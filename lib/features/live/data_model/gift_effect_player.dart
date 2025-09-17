// GiftEffectPlayer.dart
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/io_client.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:svgaplayer_flutter/svgaplayer_flutter.dart';



class GiftEffectPlayer {
  // ========= 公開參數 =========
  final bool logEnabled;
  final int memoryCacheCap;             // 記憶體 LRU 容量（解析後 item）
  final int memoryBytesCap;             // 記憶體 LRU 容量（原始 bytes）
  final int diskCacheCapMB;             // 磁碟最大容量（MB，原始 bytes）
  final int maxConcurrentDownloads;     // 全域下載併發上限
  final Duration connectionTimeout;     // 建立連線逾時
  final Duration requestTimeout;        // 單次請求逾時
  final Duration softWait;              // 首播短等待 in-flight bytes
  final Duration minAnim;               // 動畫最短顯示
  final Duration maxAnim;               // 動畫最長顯示（fallback）

  // ========= 內部狀態 =========
  final SVGAAnimationController _ctrl;
  OverlayEntry? _entry;
  bool _playing = false;
  Timer? _fallbackTimer;
  BuildContext? _lastCtx;
  AnimationStatusListener? _statusListener;

  // 播放輪次 token（讓舊回調失效）
  int _playToken = 0;

  // 下載連線
  late final IOClient _http;
  HttpClient? _raw;

  // 快取
  final _itemCache = LinkedHashMap<String, dynamic>();      // url -> MovieEntity/VideoItem（僅作預熱/加速，播放可被忽略）
  final _bytesCache = LinkedHashMap<String, Uint8List>();   // url -> bytes（播放主要依賴）

  // 磁碟路徑
  Directory? _diskDir;
  bool _diskReady = false;

  // 下載去重、下載併發控制
  final Map<String, Future<Uint8List>> _inflight = {};
  final _dlWaiters = Queue<Completer<void>>();
  int _dlPermits = 0;

  // 解碼鎖（嚴格串行）
  Completer<void>? _decodeGate;

  // 播放佇列（使用 job：url + playKey + attempts + freshOnly）
  final Queue<_GiftJob> _queue = Queue<_GiftJob>();

  // 遞增序號用來生成 playKey
  int _seq = 0;

  // 被判定為「舊 item 可能失效」的 URL
  final Set<String> _staleUrl = <String>{};

  static const _tag = '[GiftFX]';

  GiftEffectPlayer({
    required TickerProvider vsync,
    this.logEnabled = true,
    this.memoryCacheCap = 16,
    this.memoryBytesCap = 8,
    this.diskCacheCapMB = 128,
    this.maxConcurrentDownloads = 2,
    this.connectionTimeout = const Duration(seconds: 6),
    this.requestTimeout = const Duration(seconds: 20),
    this.softWait = const Duration(milliseconds: 220),
    this.minAnim = const Duration(milliseconds: 1800),
    this.maxAnim = const Duration(milliseconds: 3500),
  }) : _ctrl = SVGAAnimationController(vsync: vsync) {
    _initHttp();
    _dlPermits = maxConcurrentDownloads;
    _ensureDiskDir();
  }

  // ---------- 公開 API ----------
  void enqueue(BuildContext context, String url, {String? key}) {
    if (url.isEmpty || !url.toLowerCase().endsWith('.svga')) return;
    _lastCtx = context;
    final playKey = key ?? _genPlayKey();
    final job = _GiftJob(url: url, playKey: playKey);
    _queue.addLast(job);

    _log('enqueue: ${job.url} [key=${job.playKey}] (q=${_queue.length}) '
        'hitItem=${_itemCache.containsKey(url)} hitBytes=${_bytesCache.containsKey(url)}');

    _ensurePrefetch();
    _tryPlayNext(context);
  }

  Future<void> warmUp(List<String> urls) async {
    for (final u in urls) {
      if (u.isEmpty || !u.toLowerCase().endsWith('.svga')) continue;
      try {
        final bytes = await _getBytes(u);
        final item = await _decodeWithLock(bytes, u);
        if (item != null) _putItem(u, item);
      } catch (e) {
        _log('warmUp failed: $e for $u');
      }
    }
  }

  void dispose() {
    _playToken++; // 讓所有舊回調失效
    _fallbackTimer?.cancel();
    if (_statusListener != null) {
      try { _ctrl.removeStatusListener(_statusListener!); } catch (_) {}
      _statusListener = null;
    }
    try { _ctrl.stop(); _ctrl.videoItem = null; } catch (_) {}
    _entry?.remove(); _entry = null;

    try { _http.close(); } catch (_) {}
    try { _raw?.close(force: true); } catch (_) {}

    _inflight.clear();
    _queue.clear();
    _itemCache.clear();
    _bytesCache.clear();
    _staleUrl.clear();
  }

  // ---------- 主要流程 ----------
  void _tryPlayNext(BuildContext context) {
    if (_playing || _queue.isEmpty) return;

    // 1) 先挑「已解析 item」的（但僅作排序優先，不強制使用）
    _GiftJob? job = _queue.firstWhere(
          (j) => _itemCache.containsKey(j.url),
      orElse: () => _GiftJob.empty,
    );

    // 2) 再挑「有 bytes」的
    job = (job.isValid)
        ? job
        : _queue.firstWhere((j) => _bytesCache.containsKey(j.url), orElse: () => _GiftJob.empty);

    // 3) 都沒有就挑隊首
    if (!job.isValid) job = _queue.first;

    _queue.remove(job);
    _playing = true;
    _log('tryPlayNext → ${job.url} [key=${job.playKey}] (remain=${_queue.length})');

    _playOnce(context, job);
  }

  Future<void> _playOnce(BuildContext context, _GiftJob job) async {
    _removeOverlay();

    final url = job.url;
    try {
      dynamic item;

      // ====== 首選路徑：若不是 freshOnly 且 URL 非 stale，才嘗試重用 item ======
      if (!job.freshOnly && !_staleUrl.contains(url)) {
        final cached = _itemCache[url];
        if (cached != null) {
          _log('hit itemCache → try play (reuse item): $url [key=${job.playKey}]');
          item = cached;
        }
      }

      // ====== 沒有或不想用 cached item：用 bytes 重新 decode 作為全新 item ======
      if (item == null) {
        Uint8List? bytes = _bytesCache[url] ?? await _readFromDisk(url);
        if (bytes == null) {
          final fut = _getBytes(url);
          try {
            bytes = await fut.timeout(softWait);
          } catch (_) {
            _log('softWait miss → yield turn: $url [key=${job.playKey}]');
            _onDone(context, requeue: true, job: job);
            return;
          }
        }
        item = await _decodeWithLock(bytes, url);
        if (item == null) {
          _log('decode failed → rotate: $url [key=${job.playKey}]');
          _onDone(context, requeue: true, job: job);
          return;
        }
        // 放入 cache 供下一次排序優先（不強制重用）
        _putItem(url, item);
      }

      await _startAnimation(context, job, item);
    } on TimeoutException {
      _log('download timeout → rotate: $url [key=${job.playKey}]');
      _onDone(context, requeue: true, job: job);
    } catch (e, st) {
      _log('playOnce error: $e\n$st');
      _onDone(context, requeue: true, job: job);
    }
  }

  Future<void> _startAnimation(BuildContext context, _GiftJob job, dynamic item) async {
    final int token = ++_playToken; // 開啟新一輪
    bool started = false;

    // 清殘留
    _fallbackTimer?.cancel();
    if (_statusListener != null) {
      try { _ctrl.removeStatusListener(_statusListener!); } catch (_) {}
      _statusListener = null;
    }

    // 1) 重新建立 overlay（用唯一 key 強制 mount 新 element）
    _removeOverlay();
    _insertOverlay(context, job.playKey);

    // 2) 強制重綁 item（null → endOfFrame → item）
    try { _ctrl.stop(); } catch (_) {}
    _ctrl.videoItem = null;
    try { await SchedulerBinding.instance.endOfFrame; } catch (_) {}
    _ctrl.videoItem = item;
    try { await SchedulerBinding.instance.endOfFrame; } catch (_) {}

    // 3) 監聽與保底
    final sw = Stopwatch()..start();
    final est = _estimateDurationMs(item);

    _statusListener = (AnimationStatus s) {
      // 抓到 forward 代表真的起跑了
      if (s == AnimationStatus.forward) {
        started = true;
        _staleUrl.remove(job.url);
        _log('animation started for ${job.url} [key=${job.playKey}]');
      }
      if (s != AnimationStatus.completed) return;
      if (token != _playToken) return; // 舊輪次忽略
      _removeListenerSilently();
      _fallbackTimer?.cancel();
      final elapsed = sw.elapsed;
      final more = elapsed >= minAnim ? Duration.zero : (minAnim - elapsed);
      Future.delayed(more, () {
        if (token != _playToken) return;
        _teardownAnimation();
        _log('animation done=${elapsed.inMilliseconds}ms (+${more.inMilliseconds}ms) for ${job.url} [key=${job.playKey}]');
        _onDone(context);
      });
    };
    _ctrl.addStatusListener(_statusListener!);

    // 啟動
    await Future<void>.delayed(Duration.zero);
    _ctrl.forward(from: 0);

    // 3.1 起跑偵測踢一下：若 150ms 仍沒進入 forward，視為沒真的跑 → 用 fresh 重試一次
    Timer(const Duration(milliseconds: 150), () {
      if (token != _playToken) return;
      if (!started) {
        _log('kick: no-start within 150ms → mark stale & retry fresh: ${job.url} [key=${job.playKey}]');
        _staleUrl.add(job.url);
        _teardownAnimation();
        _retryFresh(context, job, reason: 'no-start');
      }
    });

    // 3.2 保底計時
    _fallbackTimer = Timer(Duration(milliseconds: est), () {
      if (token != _playToken) return;
      _log('fallback end @~${est}ms for ${job.url} [key=${job.playKey}] (started=$started)');
      if (!started) {
        // 還是沒跑到，丟棄舊 item 下次改 fresh
        _staleUrl.add(job.url);
        _teardownAnimation();
        _retryFresh(context, job, reason: 'fallback-no-start');
        return;
      }
      _teardownAnimation();
      _onDone(context);
    });
  }

  void _retryFresh(BuildContext context, _GiftJob job, {required String reason}) {
    if (job.attempts >= 2) {
      _log('give up retry after ${job.attempts} attempts: ${job.url} [$reason]');
      _onDone(context); // 放掉這筆，避免無限循環
      return;
    }
    final freshJob = _GiftJob(
      url: job.url,
      playKey: _genPlayKey(),
      attempts: job.attempts + 1,
      freshOnly: true,
    );
    _playing = false;
    // 立刻重試（放到佇列最前面）
    _queue.addFirst(freshJob);
    Future.microtask(() => _tryPlayNext(context));
  }

  void _removeListenerSilently() {
    if (_statusListener != null) {
      try { _ctrl.removeStatusListener(_statusListener!); } catch (_) {}
      _statusListener = null;
    }
  }

  void _teardownAnimation() {
    try { _ctrl.stop(); _ctrl.videoItem = null; } catch (_) {}
    _removeListenerSilently();
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _removeOverlay();
  }

  void _onDone(BuildContext context, {bool requeue = false, _GiftJob? job}) {
    _playing = false;
    if (requeue && job != null) {
      _queue.addLast(job);
    }
    Future.microtask(() => _tryPlayNext(context));
  }

  // ---------- 預取 ----------
  void _ensurePrefetch() {
    int room = maxConcurrentDownloads - _inflight.length;
    if (room <= 0) return;

    final seen = <String>{};
    for (final j in _queue) {
      if (room <= 0) break;
      if (!seen.add(j.url)) continue;
      if (_itemCache.containsKey(j.url) || _bytesCache.containsKey(j.url) || _inflight.containsKey(j.url)) {
        continue;
      }
      _getBytes(j.url).then((bytes) async {
        final item = await _decodeWithLock(bytes, j.url);
        if (item != null) _putItem(j.url, item);
        _nudgeIfReady(j.url);
      }).catchError((_) {});
      room--;
    }
  }

  void _nudgeIfReady(String url) {
    if (_playing) return;
    if (!_queue.any((j) => j.url == url)) return;
    final ctx = _lastCtx;
    if (ctx == null) return;
    Future.microtask(() => _tryPlayNext(ctx));
  }

  // ---------- 下載 & 快取 ----------
  Future<Uint8List> _getBytes(String url) {
    final hit = _bytesCache[url];
    if (hit != null) return Future.value(hit);

    final inflight = _inflight[url];
    if (inflight != null) return inflight;

    final completer = Completer<Uint8List>();
    _inflight[url] = completer.future;

    () async {
      try {
        final local = await _readFromDisk(url);
        if (local != null && _looksLikeSvga(local)) {
          _putBytes(url, local);
          completer.complete(local);
          return;
        }
        await _acquireDl();
        try {
          final bytes = await _downloadWithRetry(url);
          if (!_looksLikeSvga(bytes)) {
            throw const FormatException('not a valid SVGA/ZIP stream');
          }
          _putBytes(url, bytes);
          await _writeToDisk(url, bytes);
          completer.complete(bytes);
        } finally {
          _releaseDl();
        }
      } catch (e, st) {
        _log('getBytes failed: $e\n$st for $url');
        if (!completer.isCompleted) completer.completeError(e);
      } finally {
        _inflight.remove(url);
      }
    }();

    return completer.future;
  }

  Future<Uint8List> _downloadWithRetry(String url) async {
    const maxAttempts = 2;
    int attempt = 0;
    while (true) {
      attempt++;
      final sw = Stopwatch()..start();
      try {
        final rsp = await _http
            .get(Uri.parse(url), headers: const {
          HttpHeaders.cacheControlHeader: 'no-transform'
        })
            .timeout(requestTimeout);
        if (rsp.statusCode == 200 && rsp.bodyBytes.isNotEmpty) {
          sw.stop();
          final kb = (rsp.bodyBytes.length / 1024).toStringAsFixed(1);
          final ms = sw.elapsedMilliseconds == 0 ? 1 : sw.elapsedMilliseconds;
          final rate = (rsp.bodyBytes.length / 1024) / (ms / 1000);
          _log('download ok: $kb KB in ${ms}ms (${rate.toStringAsFixed(1)} KB/s) (attempt=$attempt) $url');
          return rsp.bodyBytes;
        }
        throw HttpException('http ${rsp.statusCode}, len=${rsp.bodyBytes.length}');
      } catch (e) {
        sw.stop();
        _log('download error attempt=$attempt after ${sw.elapsedMilliseconds}ms: $e for $url');
        if (attempt >= maxAttempts) rethrow;
        final base = 300 * (1 << (attempt - 1));
        final jitter = (DateTime.now().microsecond % (base ~/ 2));
        await Future.delayed(Duration(milliseconds: base + jitter));
      }
    }
  }

  Future<dynamic> _decodeWithLock(Uint8List bytes, String url) async {
    while (_decodeGate != null) {
      await _decodeGate!.future;
    }
    _decodeGate = Completer<void>();
    try {
      final sw = Stopwatch()..start();
      try {
        final item = await SVGAParser.shared.decodeFromBuffer(bytes);
        sw.stop();
        _log('decode ok ${sw.elapsedMilliseconds}ms for $url (len=${bytes.length})');
        return item;
      } catch (e) {
        sw.stop();
        _log('decode failed (${sw.elapsedMilliseconds}ms): $e → purge bytes & retry once for $url');
        _evictBytes(url);
        await _deleteFromDisk(url);
        final fresh = await _getBytes(url);
        final item = await SVGAParser.shared.decodeFromBuffer(fresh);
        _log('decode ok after refresh for $url');
        return item;
      }
    } finally {
      _decodeGate!.complete();
      _decodeGate = null;
    }
  }

  // 記憶體 LRU
  void _putItem(String url, dynamic item) {
    if (_itemCache.length >= memoryCacheCap) {
      _itemCache.remove(_itemCache.keys.first);
    }
    _itemCache[url] = item;
  }

  void _putBytes(String url, Uint8List bytes) {
    if (_bytesCache.length >= memoryBytesCap) {
      _bytesCache.remove(_bytesCache.keys.first);
    }
    _bytesCache[url] = bytes;
  }

  void _evictBytes(String url) => _bytesCache.remove(url);

  // 磁碟快取
  Future<void> _ensureDiskDir() async {
    if (_diskReady) return;
    final dir = await getApplicationDocumentsDirectory();
    _diskDir = Directory(p.join(dir.path, 'svga_cache'));
    if (!(await _diskDir!.exists())) {
      await _diskDir!.create(recursive: true);
    }
    _diskReady = true;
    _trimDiskIfNeeded();
  }

  File _fileOf(String url) {
    final name = crypto.md5.convert(utf8.encode(url)).toString() + '.svga';
    return File(p.join(_diskDir!.path, name));
  }

  Future<Uint8List?> _readFromDisk(String url) async {
    await _ensureDiskDir();
    final f = _fileOf(url);
    if (await f.exists()) {
      try {
        final bytes = await f.readAsBytes();
        if (bytes.isNotEmpty) {
          _log('disk hit: ${f.path} (${bytes.length} bytes) for $url');
          return bytes;
        }
      } catch (e) {
        _log('disk read error: $e for ${f.path}');
      }
    }
    return null;
  }

  Future<void> _writeToDisk(String url, Uint8List bytes) async {
    await _ensureDiskDir();
    final f = _fileOf(url);
    try {
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(f.path);
      _log('disk wrote: ${f.path} (${bytes.length})');
      _trimDiskIfNeeded();
    } catch (e) {
      _log('disk write error: $e for ${f.path}');
    }
  }

  Future<void> _deleteFromDisk(String url) async {
    await _ensureDiskDir();
    final f = _fileOf(url);
    try { if (await f.exists()) await f.delete(); } catch (_) {}
  }

  Future<void> _trimDiskIfNeeded() async {
    try {
      final dir = _diskDir;
      if (dir == null) return;
      final entries = await dir.list().where((e) => e is File).cast<File>().toList();
      entries.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
      int total = entries.fold(0, (s, f) => s + f.lengthSync());
      final cap = diskCacheCapMB * 1024 * 1024;
      int removed = 0;
      while (total > cap && entries.isNotEmpty) {
        final f = entries.removeAt(0);
        final len = f.lengthSync();
        await f.delete();
        total -= len;
        removed += 1;
      }
      if (removed > 0) {
        _log('disk trim: removed=$removed, remain=${entries.length}, total=${(total/1024/1024).toStringAsFixed(1)}MB');
      }
    } catch (e) {
      _log('disk trim error: $e');
    }
  }

  // ---------- 估時 ----------
  int _estimateDurationMs(dynamic item) {
    try {
      final fps = (item.FPS as int?) ??
          (item.videoSize?.FPS as int?) ??
          (item.params?.FPS as int?);
      final frames = (item.frames as int?) ??
          (item.videoSize?.frames as int?) ??
          (item.params?.frames as int?);
      if (fps != null && fps > 0 && frames != null && frames > 0) {
        final sec = frames / fps * 1.05; // 5% 緩衝
        final ms = (sec * 1000).round();
        return ms.clamp(minAnim.inMilliseconds, maxAnim.inMilliseconds);
      }
    } catch (_) {}
    return maxAnim.inMilliseconds; // 取不到就保守
  }

  // ---------- Overlay ----------
  void _insertOverlay(BuildContext context, String playKey) {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          ignoring: true,
          child: SizedBox.expand(
            child: KeyedSubtree(
              key: ValueKey<String>(playKey),
              child: SVGAImage(
                _ctrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context)?.insert(_entry!);
    _log('overlay inserted [key=$playKey]');
  }

  void _removeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  // ---------- HttpClient ----------
  void _initHttp() {
    final io = HttpClient()
      ..idleTimeout = const Duration(seconds: 15)
      ..connectionTimeout = connectionTimeout
      ..maxConnectionsPerHost = 6
      ..userAgent = 'GiftFX/1.4 (Flutter; svga)'
      ..autoUncompress = true;
    _raw = io;
    _http = IOClient(io);
  }

  // ---------- 下載併發控制 ----------
  Future<void> _acquireDl() async {
    if (_dlPermits > 0) {
      _dlPermits--;
      return;
    }
    final c = Completer<void>();
    _dlWaiters.addLast(c);
    await c.future;
  }

  void _releaseDl() {
    if (_dlWaiters.isNotEmpty) {
      _dlWaiters.removeFirst().complete();
    } else {
      _dlPermits++;
    }
  }

  // ---------- 驗流 ----------
  bool _looksLikeSvga(Uint8List b) {
    if (b.length < 64) return false;
    final pk = b[0] == 0x50 && b[1] == 0x4B; // 'P''K'
    if (pk) return true;
    final head = ascii.decode(b.sublist(0, 32), allowInvalid: true).toLowerCase();
    if (head.contains('<html') || head.contains('accessdenied') || head.startsWith('{')) return false;
    return true;
  }

  // ---------- 小工具 ----------
  String _genPlayKey() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
  void _log(String s) { if (logEnabled) debugPrint('$_tag $s'); }

  /// 立即停止禮物播放；可選擇清空佇列與已解析快取
  void stop({bool clearQueue = false, bool clearDecodedCache = false}) {
    _playToken++; // 讓所有計時器/回調失效
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _removeListenerSilently();
    try { _ctrl.stop(); _ctrl.videoItem = null; } catch (_) {}
    _removeOverlay();
    _playing = false;
    if (clearQueue) _queue.clear();
    if (clearDecodedCache) _itemCache.clear();
  }
}

class _GiftJob {
  final String url;
  final String playKey;
  final int attempts;     // 自救重試次數
  final bool freshOnly;   // 忽略 item cache，強制用 bytes 重新 decode
  const _GiftJob({
    required this.url,
    required this.playKey,
    this.attempts = 0,
    this.freshOnly = false,
  });
  static const _GiftJob empty = _GiftJob(url: '', playKey: '');
  bool get isValid => url.isNotEmpty && playKey.isNotEmpty;
}