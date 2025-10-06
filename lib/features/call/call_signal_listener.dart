import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import '../../core/error_handler.dart';
import '../../core/ws/ws_provider.dart';
import '../../data/models/gift_item.dart';
import '../../globals.dart';
import '../../l10n/l10n.dart';
import '../../routes/app_routes.dart';
import '../live/data_model/call_overlay.dart';
import '../live/gift_providers.dart';
import '../message/chat_providers.dart';
import '../message/inbox_message_banner.dart';
import '../message/message_chat_page.dart';
import '../profile/profile_controller.dart';
import 'call_abort_provider.dart';
import 'call_repository.dart';
import 'home_visible_provider.dart';
import 'incoming_call_banner.dart';
import 'incoming_call_page.dart';
import 'dart:async';

class CallSignalListener extends ConsumerStatefulWidget {
  final Widget child;
  const CallSignalListener({super.key, required this.child});

  @override
  ConsumerState<CallSignalListener> createState() => _CallSignalListenerState();
}

class _CallSignalListenerState extends ConsumerState<CallSignalListener>
    with WidgetsBindingObserver {
  final List<VoidCallback> _unsubs = [];
  bool _showingIncoming = false;
  final _ackedUuids = <String>{};

  final AudioPlayer _ring = AudioPlayer();
  bool _ringing = false;

  OverlayEntry? _incomingBanner;   // ★ 來電 Banner

  OverlayEntry? _msgBanner;
  Timer? _msgTimer;

  void _log(String msg) => debugPrint('📬[Banner] $msg');

  void _hideIncomingBanner() {
    if (_incomingBanner != null) _log('hide incoming-call banner');
    _incomingBanner?.remove();
    _incomingBanner = null;
    _showingIncoming = false;
    _stopRingtoneAndUnduck();
  }

  void _hideMsgBanner() {
    _msgTimer?.cancel();
    _msgTimer = null;

    final e = _msgBanner;
    _msgBanner = null;

    if (e == null) return;
    try {
      if (e.mounted) {
        e.remove();
        debugPrint('📬[Banner] hide message banner (removed)');
      } else {
        debugPrint('📬[Banner] skip remove: entry not mounted yet');
      }
    } catch (err) {
      debugPrint('📬[Banner] remove threw (ignored): $err');
    }
  }

  OverlayState? _findOverlay() {
    final nav = rootNavigatorKey.currentState;
    if (nav?.overlay != null) return nav!.overlay!;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) {
      try { return Overlay.of(ctx, rootOverlay: true); } catch (_) {}
    }
    try { return Overlay.of(context, rootOverlay: true); } catch (_) {}
    return null;
  }

  void _insertMsgBannerWithRetry(OverlayEntry entry, {int retry = 0}) {
    if (_msgBanner != null && identical(_msgBanner, entry) && entry.mounted) {
      debugPrint('📬[Banner] entry already mounted, skip insert');
      return;
    }

    final ov = _findOverlay();
    debugPrint('📬[Banner] insert attempt #$retry -> overlay=${ov != null}');
    if (ov != null) {
      try {
        ov.insert(entry);
        _msgBanner = entry;
        debugPrint('📬[Banner] inserted banner 👍');
        _msgTimer = Timer(const Duration(seconds: 5), () {
          debugPrint('📬[Banner] auto hide banner (timeout)');
          _hideMsgBanner();
        });
        return;
      } catch (e) {
        debugPrint('📬[Banner] insert threw: $e');
      }
    }

    // 備援：下一幀再試
    if (retry == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('📬[Banner] postFrame fallback insert');
        _insertMsgBannerWithRetry(entry, retry: 1);
      });
      // 確保真的會有一幀
      try { SchedulerBinding.instance.scheduleFrame(); } catch (_) {}
    } else if (retry == 1) {
      // 再給一次機會，用短延遲
      Timer(const Duration(milliseconds: 32), () {
        debugPrint('📬[Banner] timer fallback insert');
        _insertMsgBannerWithRetry(entry, retry: 2);
      });
    } else {
      debugPrint('📬[Banner] give up inserting banner after retries');
    }
  }


  Future<void> _startRingtoneAndDuck() async {
    if (_ringing) return;
    _ringing = true;
    try {
      await _ring.setReleaseMode(ReleaseMode.loop);
      await _ring.play(AssetSource('ringtone.wav'));
    } catch (_) {}
    // 靜音首頁影片（但仍播放）
    ref.read(homeMuteAudioProvider.notifier).state = true;
  }

  Future<void> _stopRingtoneAndUnduck() async {
    if (_ringing) {
      _ringing = false;
      try { await _ring.stop(); } catch (_) {}
    }
    // 恢復首頁影片聲音
    ref.read(homeMuteAudioProvider.notifier).state = false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final ws = ref.read(wsProvider);
    ws.ensureConnected();

    // ========= 全域攔截：任何 WS 都先嘗試 ACK =========
    _unsubs.add(ws.tapRaw(_ackRawIfNeeded));  // ★ 新增這行
    // ===============================================

    // 只看新版：來電響鈴 -> call.invite（status=0 或缺省）
    _unsubs.add(ws.on('call.invite', _onInvite));

    _unsubs.add(ws.on('call.accept', (p) {
      if ((_status(p) ?? 0) == 2) _abortAndGoHome(p);
    }));
    _unsubs.add(ws.on('call.invite', (p) {
      final st = _status(p) ?? 0;
      if (st == 2 || st == 3 || st == 4) _abortAndGoHome(p);
    }));
    _unsubs.add(ws.on('call.end', _abortAndGoHome));
    _unsubs.add(ws.on('call.cancel', _abortAndGoHome));
    _unsubs.add(ws.on('call.timeout', _abortAndGoHome));
    _unsubs.add(ws.on('room_chat', _onIncomingChatForBanner));
  }

  void _onIncomingChatForBanner(Map<String, dynamic> payload) {
    final inHome = ref.read(isLiveListVisibleProvider);
    debugPrint('📬[Banner] room_chat arrived. inHome=$inHome, bannerAlive=${_msgBanner != null}');
    if (!inHome) return;

    final me   = ref.read(userProfileProvider);
    final cdn  = me?.cdnUrl ?? '';
    final myId = int.tryParse(me?.uid ?? '') ?? -1;

    final data = _pickData(payload);

    final fromUid = _toInt(payload['uid']) ?? _toInt(data['uid']) ?? -1;
    final toUid   = _toInt(payload['to_uid']) ?? _toInt(data['to_uid']) ?? -1;
    debugPrint('📬[Banner] uids: from=$fromUid -> to=$toUid, myId=$myId');
    if (fromUid <= 0 || toUid != myId) return;

    final t = S.of(context);
    final nick = _s(data['nick_name'] ?? '${t.userWord} $fromUid');
    final avatarRaw = (() {
      final v = data['avatar'];
      if (v is List && v.isNotEmpty) return _s(v.first);
      return _s(v);
    })();
    final avatarUrl = _joinCdn2(cdn, avatarRaw);

    final content = _s(data['content']);
    debugPrint('📬[Banner] parsed nick="$nick", avatarRaw="$avatarRaw", content="$content"');

    // 禮物列表（可能還沒載入就給空）
    final gifts = ref.read(giftListProvider).maybeWhen(
      data: (v) => v,
      orElse: () => const <GiftItemModel>[],
    );

    _hideMsgBanner(); // 先清舊的（安全版）
    debugPrint('📬[Banner] will build overlay entry');

    final entry = OverlayEntry(
      builder: (_) => InboxMessageBanner(
        title: nick,
        avatarUrl: avatarUrl,
        previewContent: content,
        cdnBase: cdn,
        gifts: gifts,
        onReply: () => _openChatAndHide(fromUid, nick, avatarUrl),
      ),
    );

    _insertMsgBannerWithRetry(entry);
  }

  void _abortAndGoHome(Map p, {String? toast}) {
    final ch = _channel(p);
    if (ch.isEmpty) return;

    // 通知其他頁面/狀態：此通話已被中止
    ref.read(callAbortProvider.notifier).abort(ch);

    // 關掉可能存在的 UI：小窗、首頁 Banner
    _hideIncomingBanner();                // ★ 只關 Banner，不導航
    if (CallOverlay.isShowing) CallOverlay.hide();

    final t = S.of(rootNavigatorKey.currentContext ?? context);
    final msg = (toast == null || toast.isEmpty) ? t.peerEndedCall : toast;
    Fluttertoast.showToast(msg: msg);

    _stopRingtoneAndUnduck();

    if (_incomingBanner != null) return;

    final nav = Navigator.of(rootNavigatorKey.currentContext!, rootNavigator: true);
    nav.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  Map<String, dynamic> _dataOf(Map p) =>
      (p['data'] is Map) ? Map<String, dynamic>.from(p['data']) : const {};

  int? _asInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '');

  String _channel(Map p) => _dataOf(p)['channel_id']?.toString() ?? '';
  String _token(Map p) => (_dataOf(p)['string'] ?? _dataOf(p)['token'])?.toString() ?? '';
  int? _status(Map p) => _asInt(_dataOf(p)['status']); // 0/缺省=響鈴, 1=接通, 2=拒絕
  int? _peerUid(Map p) => _asInt(_dataOf(p)['uid']);
  String _nick(Map p) => _dataOf(p)['nick_name']?.toString() ?? S.of(context).incomingCallTitle;
  dynamic _avatarRaw(Map p) => _dataOf(p)['avatar'];
  int _flag(Map p) {
    final d = _dataOf(p);
    final v = d.containsKey('flag') ? d['flag'] : d['Flag']; // 兼容大小寫
    if (v == null) return 1;                   // 預設視訊
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 1;
  }

  String? _firstAvatarPath(dynamic v) {
    if (v == null) return null;
    if (v is List && v.isNotEmpty) {
      final s = v.first?.toString().trim();
      return (s?.isNotEmpty ?? false) ? s : null;
    }
    final s = v.toString().trim();
    return s.isNotEmpty ? s : null;
  }

  String _joinCdn(String cdn, String path) {
    if (path.startsWith('http')) return path;
    final a = cdn.endsWith('/') ? cdn.substring(0, cdn.length - 1) : cdn;
    final b = path.startsWith('/') ? path.substring(1) : path;
    return '$a/$b';
  }

  Future<void> _openChatAndHide(int partnerUid, String name, String avatarUrl) async {
    debugPrint('📬[Banner] onReply tapped -> hide and navigate');
    _hideMsgBanner();

    // 進入聊天時暫停首頁視頻（返回時恢復）
    ref.read(homePlayGateProvider.notifier).state = false;

    final route = MaterialPageRoute(
      builder: (_) => MessageChatPage(
        partnerName: name,
        partnerAvatar: avatarUrl,
        vipLevel: 0,
        statusText: 1,
        partnerUid: partnerUid,
      ),
    );

    // 封裝：真正的 push 放到下一幀，避免和 Overlay remove 同步動作在 iOS 上打架
    Future<void> _push(NavigatorState nav) async {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        debugPrint('📬[Banner] perform navigation on next frame');
        try {
          await nav.push(route);
        } finally {
          ref.read(homePlayGateProvider.notifier).state = true;
        }
      });
    }

    // 先用 rootNavigatorKey，沒有就回退用 context
    final nav1 = rootNavigatorKey.currentState;
    if (nav1 != null) {
      debugPrint('📬[Banner] use rootNavigatorKey for navigation');
      unawaited(_push(nav1));
    } else {
      debugPrint('📬[Banner] rootNavigatorKey null, fallback to context navigator');
      final nav2 = Navigator.of(context, rootNavigator: true);
      unawaited(_push(nav2));
    }
  }

  // ========= ACK：核心攔截邏輯 =========
  void _ackRawIfNeeded(dynamic raw) {
    try {
      Map<String, dynamic>? m;

      if (raw is String) {
        m = jsonDecode(raw) as Map<String, dynamic>?;
      } else if (raw is List<int>) {
        final txt = utf8.decode(raw, allowMalformed: true);
        m = jsonDecode(txt) as Map<String, dynamic>?;
      } else if (raw is Map) {
        m = Map<String, dynamic>.from(raw as Map);
      }
      if (m == null) return;

      // 1) 跳過心跳
      if (_looksLikeHeartbeat(m)) return;

      // 2) 取 uuid（先頂層，再 data/Data 裡的 uuid/id）
      final uuid = _extractUuid(m);
      if (uuid == null || uuid.isEmpty) return;

      _log('ACK uuid=$uuid sent');
      // 3) 去重後打 ACK
      if (_ackedUuids.add(uuid)) {
        unawaited(ref.read(chatRepositoryProvider).sendAck(uuid));
      }
    } catch (_) {
      // 忽略解析錯誤
    }
  }

  bool _looksLikeHeartbeat(Map<String, dynamic> m) {
    String _s(dynamic v) => v?.toString() ?? '';
    int? _i(dynamic v) => (v is num) ? v.toInt() : int.tryParse(_s(v));

    final t = _s(m['type'] ?? m['Type'] ?? m['event']).toLowerCase();
    if (t.contains('heart') || t == 'ping' || t == 'pong') return true;

    final flag = _i(m['flag'] ?? m['Flag']);
    // 如果你後端有特定的心跳 flag，補進來（例：0/1/99 之類）
    if (flag == 0 /*|| flag == 1 || flag == 99*/) return true;

    return false;
    // 若不確定，寧可少過濾（只檔明確心跳），避免漏 ACK
  }

  String? _extractUuid(Map<String, dynamic> m) {
    String? _pickStr(Map mm, List<String> ks) {
      for (final k in ks) {
        final v = mm[k];
        if (v == null) continue;
        final s = v.toString();
        if (s.isNotEmpty) return s;
      }
      return null;
    }

    // 頂層
    final top = _pickStr(m, ['uuid', 'UUID']);
    if (top != null && top.isNotEmpty) return top;

    // data/Data 裡的 uuid / id
    Map<String, dynamic> _asMap(dynamic v) =>
        (v is Map) ? v.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};

    final data = _asMap(m['data']).isNotEmpty ? _asMap(m['data']) : _asMap(m['Data']);
    final inner = _pickStr(data, ['uuid', 'UUID', 'id', 'Id']);
    return inner;
  }

  void _onInvite(Map<String, dynamic> p) {
    final st = _status(p) ?? 0;
    _log('call.invite status=$st, inHome=${ref.read(isLiveListVisibleProvider)}');

    if (st != 0) return;

    final ch = _channel(p);
    final peerUid = _peerUid(p);
    if (ch.isEmpty || peerUid == null) return;

    // 清掉上一通 abort
    ref.read(callAbortProvider.notifier).clear(ch);

    final meUid = ref.read(userProfileProvider)?.uid;
    if (meUid == null) return;

    final name = _nick(p);
    final cdn  = ref.read(userProfileProvider)?.cdnUrl ?? '';
    final avatarPath = _firstAvatarPath(_avatarRaw(p));
    final avatarUrl  = (avatarPath == null) ? '' : _joinCdn(cdn, avatarPath);
    final token = _token(p); // 可能為空
    final int flag = _flag(p);

    final inHome = ref.read(isLiveListVisibleProvider);

    if (inHome) {
      if (_incomingBanner != null) return; // 已顯示就不重複
      _showingIncoming = true;

      _incomingBanner = OverlayEntry(
        builder: (_) => IncomingCallBanner(
          callerName: name,
          avatarUrl : avatarUrl,
          flag      : flag,
          onReject  : () async {
            _hideIncomingBanner();
            unawaited(ref.read(callRepositoryProvider)
                .respondCall(channelName: ch, callId: null, accept: false)
                .timeout(const Duration(seconds: 2))
                .catchError((e) {
              // 只有真正的異常才會到這裡（124/126 已在 repo 當作 alsoOk）
              AppErrorToast.show(e);
            }));
          },
          onAccept  : () async {
            _hideIncomingBanner();
            await _acceptFromBanner(
              channel: ch,
              fromUid: peerUid,
              name: name,
              avatarUrl: avatarUrl,
              rtcTokenMaybeEmpty: token,
              flag: flag,
            );
          },
        ),
      );

      _startRingtoneAndDuck();

      // ★ 重要：等到首幀再插入；若 overlay 暫不可用，回退到整頁接聽頁，避免 UI 靜默
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final overlay = rootNavigatorKey.currentState?.overlay;
        _log('try insert incoming-call banner, overlayIsNull=${overlay==null}');

        if (overlay == null) {
          _log('fallback to full page');
          // 回退：用原本整頁接聽頁，確保有 UI
          _showingIncoming = false;
          _stopRingtoneAndUnduck();
          _pushIncomingFullPage(
            channel: ch,
            fromUid: peerUid,
            meUid: int.parse(meUid),
            name: name,
            avatarUrl: avatarUrl,
            token: token,
            flag: flag,
          );
          return;
        }
        overlay.insert(_incomingBanner!);
        _log('inserted incoming-call banner 👍');
      });

    } else {
      if (_showingIncoming) return;
      _showingIncoming = true;
      _pushIncomingFullPage(
        channel: ch,
        fromUid: peerUid,
        meUid: int.parse(meUid),
        name: name,
        avatarUrl: avatarUrl,
        token: token,
        flag: flag,
      );
    }
  }

  Future<void> _acceptFromBanner({
    required String channel,
    required int fromUid,
    required String name,
    required String avatarUrl,
    required String rtcTokenMaybeEmpty,
    required int flag,
  }) async {
    // 已被中止就不處理
    if (ref.read(callAbortProvider).contains(channel)) {
      Fluttertoast.showToast(msg: S.of(context).peerEndedCall);
      return;
    }

    // 1) 權限
    final needCam = (flag == 1);
    final req = <Permission>[Permission.microphone, if (needCam) Permission.camera];
    final statuses = await req.request();
    final micOk = statuses[Permission.microphone] == PermissionStatus.granted;
    final camOk = !needCam || statuses[Permission.camera] == PermissionStatus.granted;
    if (!micOk || !camOk) {
      final t = S.of(context);
      final msg = needCam ? t.needMicCamPermission : t.needMicPermission;
      Fluttertoast.showToast(msg: msg);
      return;
    }

    // 2) 告知後端我接聽 + 取得 token
    String? token = (rtcTokenMaybeEmpty.isNotEmpty) ? rtcTokenMaybeEmpty : null;
    final acceptFuture = ref
        .read(callRepositoryProvider)
        .respondCall(channelName: channel, callId: null, accept: true)
        .timeout(const Duration(seconds: 3))
        .catchError((e) {
      // 統一錯誤處理（常見錯誤碼給特別文案，其他交給字典）
      if (e is ApiException) {
        switch (e.code) {
          case 102: // Insufficient Quota
            Fluttertoast.showToast(msg: S.of(context).balanceNotEnough);
            break;
          case 121: // The User Is On Calling
            Fluttertoast.showToast(msg: S.of(context).calleeBusy);
            break;
          case 123: // User Offline
            Fluttertoast.showToast(msg: S.of(context).calleeOffline);
            break;
          case 125: // User Do Not Disturb Mode
            Fluttertoast.showToast(msg: S.of(context).calleeDndOn);
            break;
          default:
            AppErrorToast.show(e);
        }
      } else {
        AppErrorToast.show(e);
      }
      return null; // 告訴後續邏輯「接聽失敗」
    });

    if (token == null) {
      final resp = await acceptFuture;
      if (resp == null) {
        // 已於上方 catchError 顯示過錯誤，直接中止
        return;
      }
      final data = (resp is Map && resp['data'] is Map)
          ? Map<String, dynamic>.from(resp['data'])
          : const <String, dynamic>{};
      token = (data['string'] ?? data['token'])?.toString();
      if (token == null || token.isEmpty) {
        Fluttertoast.showToast(msg: S.of(context).acceptFailedMissingToken);
        return;
      }
    } else {
      // 已有 token，仍把接聽請求送出去（失敗會在 catchError 吐司，但不阻斷導頁）
      unawaited(acceptFuture);
    }

    // 3) 再次確認未被中止
    if (ref.read(callAbortProvider).contains(channel)) {
      Fluttertoast.showToast(msg: S.of(context).peerEndedCall);
      return;
    }

    // 4) 進房
    ref.read(homePlayGateProvider.notifier).state = false; // 可選：關首頁影片
    final me = ref.read(userProfileProvider)!;

    Navigator.of(rootNavigatorKey.currentContext!, rootNavigator: true)
        .pushReplacementNamed(
      AppRoutes.broadcaster,
      arguments: {
        'roomId'       : channel,
        'token'        : token,
        'uid'          : me.uid,
        'title'        : name,
        'hostName'     : me.displayName,
        'isCallMode'   : true,
        'asBroadcaster': true,
        'remoteUid'    : fromUid,
        'callFlag'     : needCam ? 1 : 2,
        'peerAvatar'   : avatarUrl,
      },
    );
  }

  void _pushIncomingFullPage({
    required String channel,
    required int fromUid,
    required int meUid,
    required String name,
    required String avatarUrl,
    required String token,
    required int flag,
  }) {
    Future.microtask(() async {
      try {
        final route = MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => IncomingCallPage(
            channelName : channel,
            fromUid     : fromUid,
            toUid       : meUid,
            callerName  : name,
            callerAvatar: avatarUrl,
            rtcToken    : token,
            callId      : null,
            callerFlag  : flag,
          ),
        );
        await rootNavigatorKey.currentState?.push(route);
      } finally {
        _showingIncoming = false;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(wsProvider).ensureConnected();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final u in _unsubs) { try { u(); } catch (_) {} }
    _stopRingtoneAndUnduck();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  // 取字串
  String _s(dynamic v) => v?.toString() ?? '';

  int? _toInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}');
  }

  Map<String, dynamic> _asMap(dynamic v) =>
      (v is Map) ? v.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};

  Map<String, dynamic> _pickData(Map p) =>
      _asMap(p['data']).isNotEmpty ? _asMap(p['data']) : _asMap(p['Data']);

  String _joinCdn2(String cdn, String path) {
    if (path.isEmpty || path.startsWith('http')) return path;
    final a = cdn.endsWith('/') ? cdn.substring(0, cdn.length - 1) : cdn;
    final b = path.startsWith('/') ? path.substring(1) : path;
    return '$a/$b';
  }

}
