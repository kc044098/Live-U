import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:io' show WebSocket;

enum WsStatus { disconnected, connecting, connected }
typedef WsHandler = FutureOr<void> Function(Map<String, dynamic> payload);

class WsService {
  WsService({
    required this.url,
    Map<String, String>? headers,
  }) : _headers = Map.of(headers ?? {});

  final String url;
  Map<String, String> _headers;

  IOWebSocketChannel? _channel;
  final _status = ValueNotifier<WsStatus>(WsStatus.disconnected);
  WsStatus get status => _status.value;
  ValueListenable<WsStatus> get statusListenable => _status;

  final Map<String, Map<int, WsHandler>> _handlers = {};
  int _nextId = 0;

  Timer? _heartbeatTimer;
  Timer? _appPingTimer;     // 主動送心跳（應用層 ping）的計時器
  Timer? _reconnectTimer;
  Timer? _helloTimer;
  int _retry = 0;
  bool _manuallyClosed = false;
  bool _closing = false;
  final Map<int, void Function(dynamic raw)> _rawTaps = {}; // 攔 raw frame
  final Map<int, WsHandler> _anyHandlers = {};             // 攔所有事件

  final _seenUuids = LinkedHashMap<String, int>(); // uuid -> firstSeenMs
  static const _seenTtl = Duration(minutes: 10);
  static const _seenCap = 4096;

  DateTime _lastRx = DateTime.now();

  final Duration _appPingEvery = const Duration(seconds: 30);

  // 是否送應用層 ping（除傳輸層 pingInterval 之外）
  final bool _sendAppPing = false;

  // 新增：判斷是否有授權
  bool get _hasAuth =>
      (_headers['Token']?.isNotEmpty ?? false) &&
          (_headers['X-UID']?.isNotEmpty ?? false);

  bool _wireLogEnabled = true;

  // 確保連線：沒有憑證就先不連
  Future<void> ensureConnected() async {
    debugPrint('[WS] ensureConnected() status=${_status.value} hasAuth=$_hasAuth');
    if (!_hasAuth) {
      debugPrint('[WS] skip connect: missing auth headers ($_headers)');
      return;
    }
    if (_status.value == WsStatus.connected || _status.value == WsStatus.connecting) return;
    _manuallyClosed = false;
    await _connect();
  }

  // 更新 Header：有變更就重連；沒有憑證就暫不重連
  void updateHeaders(Map<String, String> newHeaders) {
    if (mapEquals(_headers, newHeaders)) return;
    _headers = Map.of(newHeaders);
    debugPrint('[WS] headers updated: $_headers');

    if (!_hasAuth) {
      debugPrint('[WS] headers missing auth; keep disconnected');
      return;
    }
    if (_status.value == WsStatus.disconnected) {
      ensureConnected();
    } else {
      _safeClose('headers updated'); // <- 用 1000
    }
  }

  // 重連排程：沒有憑證就不要瘋狂重連
  void _scheduleReconnect() {
    if (_manuallyClosed) { debugPrint('[WS] not reconnect: manuallyClosed'); return; }
    if (!_hasAuth) {
      debugPrint('[WS] not reconnecting: missing auth headers');
      return;
    }
    _reconnectTimer?.cancel();
    final delay = Duration(seconds: _backoffSeconds());
    debugPrint('[WS] schedule reconnect in ${delay.inSeconds}s');
    _reconnectTimer = Timer(delay, ensureConnected);
  }


  /// 訂閱事件，回傳取消訂閱的函式
  VoidCallback on(String type, WsHandler handler) {
    final id = _nextId++;
    _handlers.putIfAbsent(type, () => {})[id] = handler;
    return () {
      final map = _handlers[type];
      if (map == null) return;
      map.remove(id);
      if (map.isEmpty) _handlers.remove(type);
    };
  }

  /// 發送事件（約定：{type, ...payload}）
  void send(String type, Map<String, dynamic> payload) {
    final msg = {'type': type, ...payload};
    _channel?.sink.add(jsonEncode(msg));
  }

  Future<void> close([int code = 1000, String reason = 'normal']) async {
    _manuallyClosed = true;
    _cancelAppPing();
    _cancelHeartbeat();
    _stopHelloLoop();
    _reconnectTimer?.cancel();
    await _safeClose(reason);
    _status.value = WsStatus.disconnected;
  }

  Future<void> _safeClose([String reason = 'normal']) async {
    if (_closing) return;
    _closing = true;
    try {
      // 只能用 1000（Normal Closure），或不給 code
      await _channel?.sink.close(1000, reason);
    } catch (e) {
      debugPrint('[WS] safeClose error: $e');
    } finally {
      _closing = false;
    }
  }
  // ---- internal ----

// --- connect ---
  Future<void> _connect() async {
    _status.value = WsStatus.connecting;
    try {
      final trimmed = url.trim();
      final uri = Uri.parse(trimmed);

      // 安全檢查：強制是 ws/wss
      if (uri.scheme != 'ws' && uri.scheme != 'wss') {
        throw StateError('WS URL must start with ws:// or wss://, got: $trimmed');
      }

      debugPrint('[WS] connecting to $trimmed with headers=$_headers');
      debugPrint('[WS] uri scheme=${uri.scheme} host=${uri.host} port=${uri.hasPort ? uri.port : '(default)'} path=${uri.path}');

      // 只送你後端要求的三個 header
      final headers = <String, String>{
        if (_headers['Token']?.isNotEmpty == true)           'Token': _headers['Token']!,
        if (_headers['X-UID']?.isNotEmpty == true)           'X-UID': _headers['X-UID']!,
        if (_headers['Accept-Language']?.isNotEmpty == true) 'Accept-Language': _headers['Accept-Language']!,
      };

      final socket = await WebSocket.connect(
        uri.toString(),
        headers: headers,
        // 不要 protocols / Origin / User-Agent，避免代理判政策
      );

      socket.pingInterval = const Duration(seconds: 20);

      _channel = IOWebSocketChannel(socket);
      _status.value = WsStatus.connected;
      _retry = 0;
      debugPrint('[WS] connected');

      _startAppPing();
      _startHeartbeat();
      _startHelloLoop();

      _channel!.stream.listen(
            (raw) {
          _lastRx = DateTime.now();

          // 先給所有 raw-taps
          for (final t in _rawTaps.values.toList()) {
            try { t(raw); } catch (_) {}
          }

          // 轉成文字以便 JSON 解析
          final text = raw is String ? raw : (raw is List<int> ? utf8.decode(raw) : null);
          if (text == null) { debugPrint('[WS] skip non-text frame'); return; }

          String _clip(String s, {int max = 4000}) =>
              (s.length <= max) ? s : (s.substring(0, max) + '… <truncated ${s.length - max} chars>');

          Map<String, dynamic>? data;
          try {
            final obj = jsonDecode(text);

            if (obj is Map) {
              data = obj.map((k, v) => MapEntry(k.toString(), v));
            } else if (obj is List) {
              // ✅ 詳細列印：是清單時把整個清單漂亮印出
              debugPrint('[WS] JSON list (${obj.length} items):\n'
                  '${const JsonEncoder.withIndent("  ").convert(obj)}');

              // （可選）若清單元素是 Map，逐一派發
              for (final e in obj) {
                if (e is Map) {
                  final m = e.map((k, v) => MapEntry(k.toString(), v));
                  // 與下方 Map 流程相同的派發 + 日誌
                  final typeStr = _mapType(m['type'] ?? m['flag']);
                  debugPrint('[WS] dispatch type(list-item)=$typeStr');

                  if (_isDupAndRemember(m)) continue; // 丟掉重複的 item

                  for (final h in _anyHandlers.values.toList()) {
                    try { h({'__type__': typeStr, ...m}); } catch (_) {}
                  }
                  _dispatch(typeStr, m);
                  if (typeStr == 'call') {
                    final derived = _mapCallStateToEventDynamic(m['status'] ?? m['data']?['status']) ?? 'invite';
                    for (final h in _anyHandlers.values.toList()) {
                      try { h({'__type__': 'call.$derived', ...m}); } catch (_) {}
                    }
                    _dispatch('call.$derived', m);
                  }
                }
              }
              return; // 清單已處理完
            } else {
              // ✅ 詳細列印：是單值（字串/數字/bool/null）就直接印值與原始 text
              debugPrint('[WS] JSON value (type=${obj.runtimeType}): $obj RAW:${_clip(text)}');
              return;
            }
          } catch (e) {
            // ✅ 解析失敗時也印原文（避免丟資訊）
            debugPrint('[WS] parse error: $e\nRAW:${_clip(text)}');
            return;
          }

          debugPrint('[WS] <= JSON (parsed)\n${_prettyJson(data)}');

          // 主類型（gift/recharge/room_chat/reply/notice/call/unknown）
          final typeStr = _mapType(data!['type'] ?? data['flag']);
          debugPrint('[WS] dispatch type=$typeStr');

          // 去重：命中就直接 return，不派發（但 ACK 還是會在 raw-tap 那邊送）
          if (_isDupAndRemember(data)) return;

          // 先給「所有事件攔截器」
          for (final h in _anyHandlers.values.toList()) {
            try { h({'__type__': typeStr, ...data}); } catch (_) {}
          }

          // 再派發具體型別
          _dispatch(typeStr, data);

          // 若是 call，再細分（沒有 status 就當 invite）
          if (typeStr == 'call') {
            final stateRaw = (data['status'] ?? '').toString().toLowerCase();
            final derived = _mapCallStateToEventDynamic(data['status'] ?? data['data']?['status']) ?? 'invite';
            debugPrint('[WS] event => call.$derived payload=$data');

            // 也讓 onAny 再吃一次細分事件（你想追更細可以看到 __type2__）
            for (final h in _anyHandlers.values.toList()) {
              try { h({'__type__': 'call.$derived', ...data}); } catch (_) {}
            }

            _dispatch('call.$derived', data);
          }
        },
        onDone: () {
          debugPrint('[WS] onDone code=${socket.closeCode} reason=${socket.closeReason}');
          _cancelHeartbeat();
          _stopHelloLoop();
          _onDone();
        },
        onError: (e, st) {
          debugPrint('[WS] onError: $e\n$st');
          _cancelHeartbeat();
          _stopHelloLoop();
          _onError(e);
        },
        cancelOnError: false,
      );

    } catch (e) {
      debugPrint('[WS] connect error: $e');
      _onError(e);
    }
  }

  void _startAppPing() {
    _cancelAppPing();
    if (!_sendAppPing) return;

    _appPingTimer = Timer.periodic(_appPingEvery, (_) {
      _sendPing();
    });
  }

  void _cancelAppPing() {
    _appPingTimer?.cancel();
    _appPingTimer = null;
  }

  void _sendPing() {
    final payload = {
      'type': 'ping', // 後端若要別的格式，可以改這行
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    try {
      final text = jsonEncode(payload);
      _channel?.sink.add(text);
      debugPrint('[WS] => ping $text'); // ✅ 這行每 30 秒會出現一次
    } catch (e) {
      debugPrint('[WS] ping send error: $e');
    }
  }

  // 心跳監控（逾時重連）
  void _startHeartbeat() {
    _cancelHeartbeat();
    _lastRx = DateTime.now();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      final idle = DateTime.now().difference(_lastRx);
      if (idle > const Duration(seconds: 65)) {
        debugPrint('[WS] heartbeat timeout (${idle.inSeconds}s) → reconnect');
        // 改：用安全關閉，且用 1000
        _safeClose('heartbeat timeout');
        return;
      }
    });
  }
  void _cancelHeartbeat() { _heartbeatTimer?.cancel(); _heartbeatTimer = null; }

  void _sendHelloBind() {
    final uid = _headers['X-UID'];
    final token = _headers['Token'];
    if (uid == null || token == null) return;

    final msg = {
      'flag': 5,           // 你們分類中的 notice
      'type': 'notice',
      'status': 'online',   // 或 'bind'，若後端要求
      'uid': uid,
      'token': token,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    try {
      final text = jsonEncode(msg);
      _channel?.sink.add(text);
      debugPrint('[WS] => hello/bind $text');
    } catch (_) {}
  }

// 啟動周期性重綁（避免代理或後端清了綁定表）
  void _startHelloLoop() {
    _helloTimer?.cancel();
    // 先送一次
    _sendHelloBind();
    // 之後每 60 秒送一次
    _helloTimer = Timer.periodic(const Duration(seconds: 60), (_) => _sendHelloBind());
  }

  void _stopHelloLoop() {
    _helloTimer?.cancel();
    _helloTimer = null;
  }

// 在 _dispatch 開頭也順便打一行
  void _dispatch(String type, Map<String, dynamic> payload) {
    final map = _handlers[type];
    final cnt = map?.length ?? 0;
    debugPrint('[WS] dispatch -> "$type" to $cnt handler(s)');
    if (cnt == 0) return;
    for (final h in map!.values.toList()) {
      try { h(payload); } catch (e, st) {
        debugPrint('[WS] handler error on "$type": $e\n$st');
      }
    }
  }

  void _onDone() {
    _status.value = WsStatus.disconnected;
    _scheduleReconnect();
  }

  void _onError(Object e) {
    _status.value = WsStatus.disconnected;
    _scheduleReconnect();
  }

  int _backoffSeconds() {
    // 1,2,4,8,16,30,30...
    _retry = (_retry + 1).clamp(1, 10);
    final sec = 1 << (_retry - 1);
    return sec > 30 ? 30 : sec;
  }

  String _mapType(dynamic t) {
    if (t is int) {
      switch (t) {
        case 1: return 'gift';
        case 2: return 'recharge';
        case 3: return 'live_chat';
        case 4: return 'reply';
        case 5: return 'notice';
        case 6: return 'call';
        case 8: return 'room_chat';
        case 9: return 'read';
        case 10: return 'countdown';
        default: return 'unknown';
      }
    }
    final s = t?.toString().toLowerCase() ?? '';
    if (s == '6') return 'call';
    return s.isEmpty ? 'unknown' : s;
  }

  String? _mapCallStateToEventDynamic(dynamic stateRaw) {
    if (stateRaw == null) return null;
    if (stateRaw is num && stateRaw.toInt() == 1) return 'accept';
    final s = stateRaw.toString().toLowerCase();
    switch (s) {
      case '1':
      case 'accept':
      case 'accepted':
        return 'accept';
      case 'invite':
      case 'ringing':
        return 'invite';
      case 'reject':
        return 'reject';
      case 'cancel':
        return 'cancel';
      case 'timeout':
        return 'timeout';
      case 'end':
      case 'hangup':
        return 'end';
      case 'busy':
        return 'busy';
    }
    return null;
  }

  /// 攔截「所有解析後事件」，無論事件型別
  /// 回傳取消訂閱的函式
  VoidCallback onAny(WsHandler handler) {
    final id = _nextId++;
    _anyHandlers[id] = handler;
    return () => _anyHandlers.remove(id);
  }

  /// 攔截「原始 frame（text 或 binary）」
  /// 回傳取消訂閱的函式
  VoidCallback tapRaw(void Function(dynamic raw) fn) {
    final id = _nextId++;
    _rawTaps[id] = fn;
    return () => _rawTaps.remove(id);
  }

  String _prettyJson(Map<String, dynamic> m) {
    try {
      return const JsonEncoder.withIndent('  ').convert(m);
    } catch (_) {
      return m.toString();
    }
  }

  DateTime get lastRx => _lastRx;
  Duration get idleFor => DateTime.now().difference(_lastRx);

  void forceReconnect([String reason = 'watchdog']) {
    _safeClose(reason); // 會走 onDone -> _scheduleReconnect()
  }

  bool _isDupAndRemember(Map<String, dynamic> m) {
    final uuid = _extractUuid(m);
    if (uuid == null || uuid.isEmpty) return false;

    final now = DateTime.now().millisecondsSinceEpoch;

    // 清掉過期
    if (_seenUuids.length % 128 == 0) {
      final cutoff = now - _seenTtl.inMilliseconds;
      _seenUuids.removeWhere((_, ts) => ts < cutoff);
    }

    // 命中重複（有效期內）
    final ts = _seenUuids[uuid];
    if (ts != null && now - ts <= _seenTtl.inMilliseconds) {
      debugPrint('[WS] drop duplicate uuid=$uuid');
      return true;
    }

    // 新記錄 + 簡易 LRU 截斷
    _seenUuids[uuid] = now;
    if (_seenUuids.length > _seenCap) {
      _seenUuids.remove(_seenUuids.keys.first);
    }
    return false;
  }

// 和你在 CallSignalListener 裡的版本一致：頂層或 data/Data 皆可取到
  String? _extractUuid(Map<String, dynamic> m) {
    String? pick(Map mm, List<String> ks) {
      for (final k in ks) {
        final v = mm[k];
        if (v == null) continue;
        final s = v.toString();
        if (s.isNotEmpty) return s;
      }
      return null;
    }
    final top = pick(m, ['uuid','UUID']);
    if (top != null) return top;

    Map<String, dynamic> asMap(dynamic v) =>
        (v is Map) ? v.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};

    final data = asMap(m['data']).isNotEmpty ? asMap(m['data']) : asMap(m['Data']);
    return pick(data, ['uuid','UUID','id','Id']);
  }

}
