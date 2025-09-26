import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/ws/ws_provider.dart';
import '../../globals.dart';
import '../../routes/app_routes.dart';
import '../live/data_model/call_overlay.dart';
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


  OverlayEntry? _incomingBanner;   // ★ 來電 Banner
  void _hideIncomingBanner() {
    _incomingBanner?.remove();
    _incomingBanner = null;
    _showingIncoming = false;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final ws = ref.read(wsProvider);
    ws.ensureConnected();

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
  }

  void _abortAndGoHome(Map p, {String toast = '對方已結束通話'}) {
    final ch = _channel(p);
    if (ch.isEmpty) return;

    // 通知其他頁面/狀態：此通話已被中止
    ref.read(callAbortProvider.notifier).abort(ch);

    // 關掉可能存在的 UI：小窗、首頁 Banner
    _hideIncomingBanner();                // ★ 只關 Banner，不導航
    if (CallOverlay.isShowing) CallOverlay.hide();

    if (toast.isNotEmpty) Fluttertoast.showToast(msg: toast);

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
  String _nick(Map p) => _dataOf(p)['nick_name']?.toString() ?? '來電';
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

  void _onInvite(Map<String, dynamic> p) {
    final st = _status(p) ?? 0;
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
                .catchError((_) {}));
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

      // ★ 重要：等到首幀再插入；若 overlay 暫不可用，回退到整頁接聽頁，避免 UI 靜默
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final overlay = rootNavigatorKey.currentState?.overlay;
        if (overlay == null) {
          // 回退：用原本整頁接聽頁，確保有 UI
          _showingIncoming = false;
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
      Fluttertoast.showToast(msg: '對方已結束通話');
      return;
    }

    // 1) 權限
    final needCam = (flag == 1);
    final req = <Permission>[Permission.microphone, if (needCam) Permission.camera];
    final statuses = await req.request();
    final micOk = statuses[Permission.microphone] == PermissionStatus.granted;
    final camOk = !needCam || statuses[Permission.camera] == PermissionStatus.granted;
    if (!micOk || !camOk) {
      Fluttertoast.showToast(msg: '請先授權麥克風${needCam ? "與相機" : ""}');
      return;
    }

    // 2) 告知後端我接聽 + 取得 token
    String? token = (rtcTokenMaybeEmpty.isNotEmpty) ? rtcTokenMaybeEmpty : null;
    final acceptFuture = ref.read(callRepositoryProvider)
        .respondCall(channelName: channel, callId: null, accept: true)
        .timeout(const Duration(seconds: 3))
        .catchError((_) => null);

    if (token == null) {
      final resp = await acceptFuture;
      final data = (resp is Map && resp['data'] is Map)
          ? Map<String, dynamic>.from(resp['data'])
          : const <String, dynamic>{};
      token = (data['string'] ?? data['token'])?.toString();
      if (token == null || token.isEmpty) {
        Fluttertoast.showToast(msg: '接聽失敗：缺少通話憑證');
        return;
      }
    } else {
      unawaited(acceptFuture);
    }

    // 3) 再次確認未被中止
    if (ref.read(callAbortProvider).contains(channel)) {
      Fluttertoast.showToast(msg: '對方已結束通話');
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
