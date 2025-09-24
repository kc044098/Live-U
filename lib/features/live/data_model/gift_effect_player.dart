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

  bool _disposed = false;

  // 下載去重、下載併發控制
  final Map<String, Future<Uint8List>> _inflight = {}; // 同 URL 併發合流，但不做任何快取
  final _dlWaiters = Queue<Completer<void>>();
  int _dlPermits = 0;

  // 播放佇列（僅 url + playKey）
  final Queue<_GiftJob> _queue = Queue<_GiftJob>();
  int _seq = 0;

  static const _tag = '[GiftFX-NO-CACHE]';

  GiftEffectPlayer({
    required TickerProvider vsync,
    this.logEnabled = true,
    this.maxConcurrentDownloads = 2,
    this.connectionTimeout = const Duration(seconds: 6),
    this.requestTimeout = const Duration(seconds: 20),
    this.softWait = const Duration(milliseconds: 220),
    this.minAnim = const Duration(milliseconds: 1800),
    this.maxAnim = const Duration(milliseconds: 3500),
  }) : _ctrl = SVGAAnimationController(vsync: vsync) {
    _initHttp();
    _dlPermits = maxConcurrentDownloads;
  }

  // ---------- 公開 API ----------
  void enqueue(BuildContext context, String url, {String? key}) {
    if (_disposed) return;
    if (url.isEmpty || !url.toLowerCase().endsWith('.svga')) return;
    _lastCtx = context;
    final playKey = key ?? _genPlayKey();
    final job = _GiftJob(url: url, playKey: playKey);
    _queue.addLast(job);
    _log('enqueue: ${job.url} [key=${job.playKey}] (q=${_queue.length})');

    _tryPlayNext(context);
  }

  // 無快取模式：warmUp 不做任何事（保留 API 以防外部呼叫）
  Future<void> warmUp(List<String> urls) async {}

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    _playToken++; // 讓所有舊回調失效
    _fallbackTimer?.cancel();
    if (_statusListener != null) {
      try { _ctrl.removeStatusListener(_statusListener!); } catch (_) {}
      _statusListener = null;
    }
    try { _ctrl.stop(); _ctrl.videoItem = null; } catch (_) {}
    _entry?.remove(); _entry = null;

    try { _ctrl.dispose(); } catch (_) {}

    try { _http.close(); } catch (_) {}
    try { _raw?.close(force: true); } catch (_) {}

    _inflight.clear();
    _queue.clear();
  }

  // ---------- 主要流程 ----------
  void _tryPlayNext(BuildContext context) {
    if (_playing || _queue.isEmpty) return;
    final job = _queue.removeFirst();
    _playing = true;
    _log('tryPlayNext → ${job.url} [key=${job.playKey}] (remain=${_queue.length})');
    _playOnce(context, job);
  }

  Future<void> _playOnce(BuildContext context, _GiftJob job) async {
    _removeOverlay();

    final url = job.url;
    try {
      // 每次都重新抓 & 重新解碼（不讀任何本地快取）
      Uint8List bytes;
      final fut = _getBytesFresh(url);
      try {
        bytes = await fut.timeout(softWait);
      } catch (_) {
        // 軟等待逾時：把這筆放到佇列末端，先讓後面可能較快的禮物跑
        _log('softWait miss → rotate: $url [key=${job.playKey}]');
        _onDone(context, requeue: true, job: job);
        return;
      }

      final item = await _decode(bytes, url);
      if (item == null) {
        _log('decode failed → drop: $url [key=${job.playKey}]');
        _onDone(context); // 丟掉這筆，避免轉圈
        return;
      }

      await _startAnimation(context, job, item);
    } on TimeoutException {
      _log('download timeout → drop: $url [key=${job.playKey}]');
      _onDone(context);
    } catch (e, st) {
      _log('playOnce error: $e\n$st');
      _onDone(context);
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

    // 1) 重新建立 overlay
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
      if (s == AnimationStatus.forward) {
        started = true;
        _log('animation started for ${job.url} [key=${job.playKey}]');
      }
      if (s != AnimationStatus.completed) return;
      if (token != _playToken) return;
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

    await Future<void>.delayed(Duration.zero);
    _ctrl.forward(from: 0);

    // 150ms 還沒 forward → 直接結束這筆（不用任何「重用」或「fresh retry」）
    Timer(const Duration(milliseconds: 150), () {
      if (token != _playToken) return;
      if (!started) {
        _log('kick: no-start within 150ms → drop: ${job.url} [key=${job.playKey}]');
        _teardownAnimation();
        _onDone(context);
      }
    });

    // 保底結束
    _fallbackTimer = Timer(Duration(milliseconds: est), () {
      if (token != _playToken) return;
      _log('fallback end @~${est}ms for ${job.url} [key=${job.playKey}] (started=$started)');
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

  void _onDone(BuildContext context, {bool requeue = false, _GiftJob? job}) {
    _playing = false;
    if (requeue && job != null) {
      _queue.addLast(job);
    }
    Future.microtask(() => _tryPlayNext(context));
  }

  // ---------- 純下載（每次都抓新資料；只有併發合流） ----------
  Future<Uint8List> _getBytesFresh(String url) {
    final inflight = _inflight[url];
    if (inflight != null) return inflight; // 同一時間同一 URL 合流

    final completer = Completer<Uint8List>();
    _inflight[url] = completer.future;

    () async {
      try {
        await _acquireDl();
        try {
          final bytes = await _downloadWithRetry(url);
          if (!_looksLikeSvga(bytes)) {
            throw const FormatException('not a valid SVGA/ZIP stream');
          }
          completer.complete(bytes);
        } finally {
          _releaseDl();
        }
      } catch (e, st) {
        _log('getBytesFresh failed: $e\n$st for $url');
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

  Future<dynamic> _decode(Uint8List bytes, String url) async {
    try {
      final sw = Stopwatch()..start();
      final item = await SVGAParser.shared.decodeFromBuffer(bytes);
      sw.stop();
      _log('decode ok ${sw.elapsedMilliseconds}ms for $url (len=${bytes.length})');
      return item;
    } catch (e) {
      _log('decode failed: $e for $url');
      return null;
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
    return maxAnim.inMilliseconds;
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

  /// 立即停止禮物播放；（無快取，清佇列即可）
  void stop({bool clearQueue = false, bool clearDecodedCache = false}) {
    if (_disposed) return;
    _playToken++; // 讓所有計時器/回調失效
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _removeListenerSilently();
    try { _ctrl.stop(); _ctrl.videoItem = null; } catch (_) {}
    _removeOverlay();
    _playing = false;
    if (clearQueue) _queue.clear();
  }
}

class _GiftJob {
  final String url;
  final String playKey;
  const _GiftJob({required this.url, required this.playKey});
  bool get isValid => url.isNotEmpty && playKey.isNotEmpty;
}
