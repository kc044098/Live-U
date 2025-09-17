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

  // 播放輪次 token（用來讓舊回調失效）
  int _playToken = 0;

  // 同 URL 播放次數（用來定期「刷新 item」）
  final Map<String, int> _replayCount = {};
  static const int _freshEveryN = 4; // 播 4 次，第 5 次前會用 bytes 重新 decode 一個新 item

  // 下載連線
  late final IOClient _http;
  HttpClient? _raw;

  // 快取
  final _itemCache = LinkedHashMap<String, dynamic>();      // url -> MovieEntity/VideoItem
  final _bytesCache = LinkedHashMap<String, Uint8List>();   // url -> bytes

  // 磁碟路徑
  Directory? _diskDir;
  bool _diskReady = false;

  // 下載去重、下載併發控制
  final Map<String, Future<Uint8List>> _inflight = {};
  final _dlWaiters = Queue<Completer<void>>();
  int _dlPermits = 0;

  // 解碼鎖（嚴格串行）
  Completer<void>? _decodeGate;

  // 播放佇列
  final Queue<String> _queue = Queue<String>();

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
  void enqueue(BuildContext context, String url) {
    if (url.isEmpty || !url.toLowerCase().endsWith('.svga')) return;
    _lastCtx = context;
    _queue.addLast(url);
    _log('enqueue: $url (q=${_queue.length}) '
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
  }

  // ---------- 主要流程 ----------
  void _tryPlayNext(BuildContext context) {
    if (_playing || _queue.isEmpty) return;

    // 1) 先挑「已解析 item」的
    String? url = _queue.firstWhere(
          (u) => _itemCache.containsKey(u),
      orElse: () => '',
    );
    // 2) 再挑「有 bytes」的
    url = (url?.isNotEmpty == true)
        ? url
        : _queue.firstWhere((u) => _bytesCache.containsKey(u), orElse: () => '');

    // 3) 都沒有就挑隊首
    if (url == null || url.isEmpty) url = _queue.first;

    _queue.remove(url);
    _playing = true;
    _log('tryPlayNext → $url (remain=${_queue.length})');

    _playOnce(context, url);
  }

  Future<void> _playOnce(BuildContext context, String url) async {
    _removeOverlay();

    try {
      // 1) 秒播：item 已在記憶體
      dynamic item = _itemCache[url];
      if (item != null) {
        item = await _prepareItemForPlay(url, item);
        _log('hit itemCache → play: $url');
        await _startAnimation(context, url, item);
        return;
      }

      // 2) bytes 在記憶體或磁碟
      Uint8List? bytes = _bytesCache[url] ?? await _readFromDisk(url);
      if (bytes != null) {
        _log('have bytes → decode & play: $url (len=${bytes.length})');
        item = await _decodeWithLock(bytes, url);
        if (item != null) {
          _putItem(url, item);
          item = await _prepareItemForPlay(url, item);
          await _startAnimation(context, url, item);
          return;
        }
        // 解碼失敗，自癒：清掉，走下載
        _evictBytes(url);
        await _deleteFromDisk(url);
      }

      // 3) 無快取：啟動下載（共用 in-flight）
      final fut = _getBytes(url);

      // 3.1 短等待（soft），避免任何等待 UI
      try {
        bytes = await fut.timeout(softWait);
      } catch (_) {
        // 不顯示等待 UI，等 bytes 到齊自動喚醒
        _log('softWait miss → yield turn: $url');
        _onDone(context, requeue: true, url: url);
        return;
      }

      // 3.2 取得 bytes 後 decode & play
      item = await _decodeWithLock(bytes, url);
      if (item == null) {
        _log('decode failed after download → rotate: $url');
        _onDone(context, requeue: true, url: url);
        return;
      }
      _putItem(url, item);
      item = await _prepareItemForPlay(url, item);
      await _startAnimation(context, url, item);
    } on TimeoutException {
      _log('download timeout → rotate: $url');
      _onDone(context, requeue: true, url: url);
    } catch (e, st) {
      _log('playOnce error: $e\n$st');
      _onDone(context, requeue: true, url: url);
    }
  }

  // 第 N 次播放前，必要時用 bytes 重新 decode 產生**全新 item**，避免「同一實例」不重繪
  Future<dynamic> _prepareItemForPlay(String url, dynamic item) async {
    final cnt = _replayCount[url] ?? 0;
    // 第 4 次後（要播第 5 次）刷新 item
    if (cnt >= _freshEveryN - 1) {
      try {
        final bytes = _bytesCache[url] ?? await _readFromDisk(url) ?? await _getBytes(url);
        final fresh = await _decodeWithLock(bytes, url);
        if (fresh != null) {
          _putItem(url, fresh);
          _replayCount[url] = 0;
          _log('freshened item before replay #${cnt + 1}: $url');
          return fresh;
        }
      } catch (e) {
        _log('freshen failed (use old item): $e');
      }
    }
    _replayCount[url] = cnt + 1;
    return item;
  }

  Future<void> _startAnimation(BuildContext context, String url, dynamic item) async {
    final int token = ++_playToken; // 開啟新一輪

    // 先清任何殘留 listener / 計時器
    _fallbackTimer?.cancel();
    if (_statusListener != null) {
      try { _ctrl.removeStatusListener(_statusListener!); } catch (_) {}
      _statusListener = null;
    }

    // 1) 重新建立 overlay（確保真的會重繪）
    _removeOverlay();
    _insertOverlay(context);

    // 2) 強制重綁 item（null → endOfFrame → item）
    try { _ctrl.stop(); } catch (_) {}
    _ctrl.videoItem = null;
    // 等待一幀，讓 widget 樹確實完成清空
    try { await SchedulerBinding.instance.endOfFrame; } catch (_) {}
    _ctrl.videoItem = item;
    // 再等一幀，讓第一幀布局/貼圖準備好
    try { await SchedulerBinding.instance.endOfFrame; } catch (_) {}

    // 3) 安裝 listener
    final sw = Stopwatch()..start();
    final est = _estimateDurationMs(item);

    _statusListener = (AnimationStatus s) {
      if (s != AnimationStatus.completed) return;
      if (token != _playToken) return; // 舊輪次回調，忽略
      _removeListenerSilently();
      _fallbackTimer?.cancel();
      final elapsed = sw.elapsed;
      final more = elapsed >= minAnim ? Duration.zero : (minAnim - elapsed);
      Future.delayed(more, () {
        if (token != _playToken) return;
        _teardownAnimation();
        _log('animation done=${elapsed.inMilliseconds}ms (+${more.inMilliseconds}ms) for $url');
        _onDone(context);
      });
    };
    _ctrl.addStatusListener(_statusListener!);

    // 4) 啟動動畫（下一個 microtask，確保第一幀已準備）
    await Future<void>.delayed(Duration.zero);
    _ctrl.forward(from: 0);

    // 5) 保底計時
    _fallbackTimer = Timer(Duration(milliseconds: est), () {
      if (token != _playToken) return;
      _log('fallback end @~${est}ms for $url');
      _teardownAnimation();
      _onDone(context);
    });
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

  void _onDone(BuildContext context, {String? url, bool requeue = false}) {
    _playing = false;
    if (requeue && url != null) {
      _queue.addLast(url);
    }
    // 立刻嘗試下一個
    Future.microtask(() => _tryPlayNext(context));
  }

  // ---------- 預取 ----------
  void _ensurePrefetch() {
    int room = maxConcurrentDownloads - _inflight.length;
    if (room <= 0) return;

    for (final u in _queue) {
      if (room <= 0) break;
      if (_itemCache.containsKey(u) || _bytesCache.containsKey(u) || _inflight.containsKey(u)) {
        continue;
      }
      _getBytes(u).then((bytes) async {
        final item = await _decodeWithLock(bytes, u);
        if (item != null) _putItem(u, item);
        _nudgeIfReady(u);
      }).catchError((_) {});
      room--;
    }
  }

  void _nudgeIfReady(String url) {
    if (_playing) return;
    if (!_queue.contains(url)) return;
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
    unawaited(_trimDiskIfNeeded());
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
      unawaited(_trimDiskIfNeeded());
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
  void _insertOverlay(BuildContext context) {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          ignoring: true,
          child: SizedBox.expand(
            child: SVGAImage(
              _ctrl,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
    Overlay.of(context)?.insert(_entry!);
    _log('overlay inserted');
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
      ..userAgent = 'GiftFX/1.2 (Flutter; svga)'
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
