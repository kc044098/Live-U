import 'dart:async';
import 'dart:io';
import 'package:djs_live_stream/features/call/rtc_engine_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/ws/ws_provider.dart';
import '../../globals.dart';
import '../../routes/app_routes.dart' hide routeObserver;
import '../live/data_model/call_overlay.dart';
import '../live/mini_call_view.dart';
import '../profile/profile_controller.dart';
import 'call_repository.dart';

import 'package:flutter_svg/flutter_svg.dart';

enum CalleeState { online, busy, offline }

class CallRequestPage extends ConsumerStatefulWidget {
  final String broadcasterId;
  final String broadcasterName;
  final String broadcasterImage;
  final bool isVideoCall;

  /// 新增：對方狀態（預設 online）
  final CalleeState calleeState;

  const CallRequestPage({
    super.key,
    required this.broadcasterId,
    required this.broadcasterName,
    required this.broadcasterImage,
    this.isVideoCall = true,

    // ✅ 向下相容：若舊程式仍傳 isBusy，會自動轉成 busy，否則 online
    CalleeState? calleeState,
    @Deprecated('Use calleeState instead') bool? isBusy,
  }) : calleeState = calleeState ?? (isBusy == true ? CalleeState.busy : CalleeState.online);

  @override
  ConsumerState<CallRequestPage> createState() => _CallRequestPageState();
}

class _CallRequestPageState extends ConsumerState<CallRequestPage>
    with WidgetsBindingObserver, RouteAware {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _busyPlayer = AudioPlayer();
  final List<VoidCallback> _wsUnsubs = [];
  final _rtc = RtcEngineManager();

  Timer? _timeoutTimer;

  String? _channelId;     // 一律使用 data.channel_id / data.channel_name
  String? _callerToken;   // 主叫 token（liveCall 回來）
  int? _callerUid;        // 我方 uid（若後端有回）
  int? _calleeUid;        // 對方 uid

  bool _finished = false;
  bool _cancelled = false;
  bool _sentCancel = false;
  int _freeAtSec = 0;

  bool _inMini = false;

  static const String _kToastTimeout = '電話撥打超時，對方無回應';

  BuildContext get _rootCtx =>
      rootNavigatorKey.currentContext ?? Navigator.of(context, rootNavigator: true).context;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 把非同步啟動流程移出去；放到 frame 之後做，避免在 build 前用到 context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kickoffFlow();
    });

  }

  // 啟動整體流程（同步入口）
  void _kickoffFlow() {
    switch (widget.calleeState) {
      case CalleeState.busy:
        _playUnavailableTone();
        _startTimeout(toast: '對方忙線中');
        break;
      case CalleeState.offline:
        _playUnavailableTone();
        _startTimeout(toast: '對方不在線');
        break;
      case CalleeState.online:
        _handleOnlineFlow(); // 非同步，但不要在這裡 await
        break;
    }
  }

  // 在線時的非同步處理：權限 -> 鈴聲 -> 撥號 -> 監聽
  Future<void> _handleOnlineFlow() async {
    final ok = await ensureMicCam(
      needCam: widget.isVideoCall == true,
      context: context,
    );
    if (!mounted) return;
    if (!ok) {
      Fluttertoast.showToast(msg: '請先授權相機與麥克風');
      return; // ensureMicCam 內已處理返回或引導設定
    }

    await _playRingtone();
    if (!mounted) return;

    _initiateCall();
    _listenSignaling();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_cancelled && !_sentCancel) {
      // 保底通知一次
      unawaited(_notifyCancelOnce());
    }
    _timeoutTimer?.cancel();
    for (final u in _wsUnsubs) { try { u(); } catch (_) {} }
    _wsUnsubs.clear();

    _audioPlayer.stop();
    _audioPlayer.dispose();
    _busyPlayer.stop();
    _busyPlayer.dispose();

    WakelockPlus.disable();
    super.dispose();
  }

  Future<bool> ensureMicCam({required bool needCam, BuildContext? context}) async {
    final req = <Permission>[Permission.microphone, if (needCam) Permission.camera];
    final before = await Future.wait(req.map((p) => p.status));
    final res = await req.request();
    final micOk = res[Permission.microphone] == PermissionStatus.granted;
    final camOk = !needCam || res[Permission.camera] == PermissionStatus.granted;

    if (micOk && camOk) return true;

    // 若永久拒絕 → 引導去設定
    final perma = res.values.any((s) => s.isPermanentlyDenied);
    if (perma) {
      Fluttertoast.showToast(msg: '請到系統設定開啟相機/麥克風權限');
      unawaited(openAppSettings());
    }
    if (context != null && Navigator.of(context).canPop()) Navigator.of(context).pop();
    return false;
  }

  void _goMini() {
    _inMini = true;
    CallOverlay.show(
      navigatorKey: rootNavigatorKey,
      child: MiniCallView(
        rootContext: rootNavigatorKey.currentContext!,
        roomId: _channelId ?? 'pending',
        isVoice: !widget.isVideoCall,
        remoteUid: _calleeUid,
        onExpand: () {
          _inMini = false;
          CallOverlay.hide();
          Navigator.of(rootNavigatorKey.currentContext!).push(
            MaterialPageRoute(builder: (_) => CallRequestPage(
              broadcasterId: widget.broadcasterId,
              broadcasterName: widget.broadcasterName,
              broadcasterImage: widget.broadcasterImage,
              calleeState: widget.calleeState,
              isVideoCall: widget.isVideoCall,
            )),
          );
        },
        // ← 不要傳 onHangup: 讓小窗無掛斷鈕
      ),
    );

    // 可選：把首頁頂上來，讓本頁留在棧中持續聽 WS
    Navigator.of(rootNavigatorKey.currentContext!).pushNamed(AppRoutes.home);
  }

  // ========= 原本撥號流程（略帶清理） =========
  Future<void> _playUnavailableTone() async {
    await _busyPlayer.setReleaseMode(ReleaseMode.loop);
    await _busyPlayer.play(AssetSource('unavailable_phone.mp3'));
  }

  Future<void> _playRingtone() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('ringtone.wav'));
  }

  Future<void> _initiateCall() async {
    try {
      await [Permission.microphone, Permission.camera].request();
      await WakelockPlus.enable();

      final flag = widget.isVideoCall ? 1 : 2;
      final resp = await ref.read(callRepositoryProvider).liveCall(
        flag: flag,
        toUid: int.parse(widget.broadcasterId),
      );

      // ★ 先看 code
      final int code = (resp['code'] is num) ? (resp['code'] as num).toInt()
          : int.tryParse('${resp['code'] ?? ''}') ?? 0;

      if (code == 100) {
        final String msg = (resp['message']?.toString() ?? '撥打失敗');
        if (msg.contains('Request Failed')) {
          Fluttertoast.showToast(msg: '電話撥打失敗 ～');
          await _audioPlayer.stop();
          if (mounted) Navigator.pop(context);
          return;
        }
      }

      if (code == 102) {
        // 餘額不足 → 提示並關閉頁面
        Fluttertoast.showToast(msg: '餘額不足, 請前往充值～');
        await _audioPlayer.stop();
        if (mounted) Navigator.pop(context);
        return;
      }
      if (code != 200) {
        // 其他非 200 錯誤
        final String msg = (resp['message']?.toString() ?? '撥打失敗');
        Fluttertoast.showToast(msg: msg);
        await _audioPlayer.stop();
        if (mounted) Navigator.pop(context);
        return;
      }

      // ★ 到這裡才是成功狀態，開始解析 data
      final Map<String, dynamic> data =
      (resp['data'] is Map) ? Map<String, dynamic>.from(resp['data'])
          : <String, dynamic>{};

      _channelId   = (data['channel_id'] ?? data['channel_name'] ?? data['channle_name'])?.toString();
      _callerToken = (data['string'] ?? data['token'])?.toString();
      _callerUid   = (data['from_uid'] as num?)?.toInt() ?? (data['uid'] as num?)?.toInt();
      _calleeUid   = (data['to_uid'] as num?)?.toInt();

      final fa = data['free_at'];
      _freeAtSec = (fa is num) ? fa.toInt() : int.tryParse(fa?.toString() ?? '') ?? 0;

      if (_channelId == null || _channelId!.isEmpty) {
        throw '電話撥打失敗 _channelId 空';
      }
      if (_callerToken == null || _callerToken!.isEmpty) {
        throw '電話撥打失敗 _callerToken 空';
      }

      // ★ 成功後才啟動超時計時
      _startTimeout();

    } catch (e) {
      if (_cancelled) return;
      debugPrint('電話撥打失敗：$e');
      Fluttertoast.showToast(msg: "電話撥打失敗, 請稍後再撥");
      await _audioPlayer.stop();
      if (mounted) Navigator.pop(context);
    }
  }

  // ---- WS helpers（只看 data.*）----
  Map<String, dynamic> _dataOf(Map p) =>
      (p['data'] is Map) ? Map<String, dynamic>.from(p['data']) : const {};
  int? _asInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '');
  String _ch(Map p) => _dataOf(p)['channel_id']?.toString() ?? '';
  int? _status(Map p) => _asInt(_dataOf(p)['status']); // 1=對方接通, 2=對方拒絕
  int? _peerUid(Map p) => _asInt(_dataOf(p)['uid']);
  int _flagOf(Map p) {
    final data = _dataOf(p);
    final v = data['flag'];
    if (v == null) return 1;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 1;
  }

  bool _sameCall(Map p) {
    final ch = _ch(p);
    if (_channelId != null && _channelId!.isNotEmpty && ch.isNotEmpty) {
      return ch == _channelId;
    }
    final peer = _peerUid(p);
    return (_calleeUid != null && peer == _calleeUid);
  }

  void _listenSignaling() {
    final ws = ref.read(wsProvider);
    bool _navigated = false;

    Future<void> _goToRoom({required int callFlag}) async {
      if (_cancelled || _finished || _navigated) return;
      _navigated = true;
      _finished  = true;

      await _audioPlayer.stop();
      _timeoutTimer?.cancel();

      // ✅ 先關小窗（若目前在 mini）
      if (CallOverlay.isShowing) {
        CallOverlay.hide();
        // 小等一幀，避免 overlay 殘留在新頁上方
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }

      final myName = ref.read(userProfileProvider)?.displayName ?? '';

      // ✅ 直接導到直播頁（用 root navigator）
      Navigator.of(_rootCtx).pushNamed(
        AppRoutes.broadcaster,
        arguments: {
          'roomId'       : _channelId,
          'token'        : _callerToken,
          'uid'          : _callerUid ?? 0,
          'title'        : widget.broadcasterName,
          'hostName'     : myName,
          'isCallMode'   : true,
          'asBroadcaster': true,
          'remoteUid'    : _calleeUid,
          'callFlag'     : callFlag,               // 1=video, 2=voice
          'peerAvatar'   : widget.broadcasterImage,
          'free_at'      : _freeAtSec,
        },
      );
    }

    // 接聽/拒絕
    _wsUnsubs.add(ws.on('call.accept', (p) async {
      if (_cancelled || !_sameCall(p)) return;
      final st = _status(p);
      if (st == 1) {
        final peerFlag = _flagOf(p);               // 1=video, 2=voice
        final myPrefVideo = widget.isVideoCall;    // 我方意願
        final wantVideo = myPrefVideo && (peerFlag == 1);
        final int callFlag = wantVideo ? 1 : 2;
        await _goToRoom(callFlag: callFlag);
      } else if (st == 2) {
        await _endWithToast('對方已拒絕');
      }
    }));

    _wsUnsubs.add(ws.on('call.invite', (p) async {
      if (_cancelled || !_sameCall(p)) return;
      if (_status(p) == 2) await _endWithToast('對方已拒絕');
    }));
  }

  void _startTimeout({ String? toast}) {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(Duration(seconds: 30), () async {
      if (_cancelled) return;
      await _endWithToast(toast ?? _kToastTimeout);
    });
  }

  Future<void> _endWithToast(String msg) async {
    if (_finished) return;
    _finished = true;

    for (final u in _wsUnsubs) { try { u(); } catch (_) {} }
    _wsUnsubs.clear();
    _timeoutTimer?.cancel();

    if (!_cancelled && msg.isNotEmpty) {
      Fluttertoast.showToast(msg: msg);
    }

    // 停止聲音與 RTC
    unawaited(_audioPlayer.stop());
    unawaited(_busyPlayer.stop());
    unawaited(_rtc.safeLeave().timeout(const Duration(seconds: 2), onTimeout: () {}));

    // ✅ 關小窗 + 清棧回首頁
    _closeMiniAndGoHome();
  }

  Future<void> _notifyCancelOnce() async {
    if (_sentCancel) return;
    _sentCancel = true;

    final channel = _channelId;
    if (channel == null || channel.isEmpty) return;

    try {
      await ref.read(callRepositoryProvider)
          .respondCall(channelName: channel, callId: null, accept: false)
          .timeout(const Duration(seconds: 2));
    } catch (_) { /* ignore */ }
  }

  Future<void> _cancelByUser() async {
    if (_finished) return;
    _finished = true;
    _cancelled = true;

    _timeoutTimer?.cancel();
    unawaited(_audioPlayer.stop());
    unawaited(_busyPlayer.stop());
    unawaited(_notifyCancelOnce().timeout(const Duration(seconds: 2), onTimeout: () {}));
    unawaited(_rtc.safeLeave().timeout(const Duration(seconds: 2), onTimeout: () {}));

    // ✅ 關小窗 + 清棧回首頁
    _closeMiniAndGoHome();
  }

  void _closeMiniAndGoHome() async {
    if (CallOverlay.isShowing) {
      CallOverlay.hide();
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }

    final nav = Navigator.of(_rootCtx);

    if (_inMini) {
      int popped = 0;
      while (popped < 2 && nav.canPop()) {
        nav.pop();
        popped++;
      }
      _inMini = false;
      if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
        if (nav.canPop()) {
          nav.pop();
        } else {
          nav.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
        }
      }
    } else {
      if (nav.canPop()) {
        nav.pop();
      } else {
        nav.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
      }
    }
  }

  String _statusTextFor(CalleeState s) {
    switch (s) {
      case CalleeState.busy:    return '對方忙線中！';
      case CalleeState.offline: return '對方不在線';
      case CalleeState.online:  return '正在接通中...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final imgProvider = (widget.broadcasterImage.isEmpty)
        ? const AssetImage('assets/my_icon_defult.jpeg') as ImageProvider
        : NetworkImage(widget.broadcasterImage);

    return WillPopScope(
      onWillPop: () async { _goMini(); return false; },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(child: Image.asset('assets/bg_calling.png', fit: BoxFit.cover)),
            Positioned.fill(child: Container(color: Colors.black.withOpacity(0.4))),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: top + 24, bottom: 32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 160),
                      CircleAvatar(radius: 60, backgroundImage: imgProvider),
                      const SizedBox(height: 32),
                      Text(
                        widget.broadcasterName,
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                        overflow: TextOverflow.ellipsis, // 避免長名爆版
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _statusTextFor(widget.calleeState),
                        style: const TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 240),
                      GestureDetector(
                        onTap: _cancelByUser,
                        child: SvgPicture.asset('assets/call_end.svg', width: 64, height: 64),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 左上：縮小（App 內 Mini）
            Positioned(
              top: top + 8, left: 8,
              child: IconButton(
                icon: Image.asset('assets/zoom.png', width: 20, height: 20),
                onPressed: _goMini,
                tooltip: '縮小畫面',
                splashRadius: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
