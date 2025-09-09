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

class CallRequestPage extends ConsumerStatefulWidget {
  final String broadcasterId;     // 對方 uid（顯示用）
  final String broadcasterName;
  final String broadcasterImage;
  final bool isBusy;
  final bool isVideoCall;

  const CallRequestPage({
    super.key,
    required this.broadcasterId,
    required this.broadcasterName,
    required this.broadcasterImage,
    this.isBusy = false,
    this.isVideoCall = true,
  });

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

  static const String _kToastTimeout = '電話撥打超時，對方無回應';

  BuildContext get _rootCtx =>
      rootNavigatorKey.currentContext ?? Navigator.of(context, rootNavigator: true).context;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.isBusy) {
      // ✅ 忙碌：不真正撥號、不播原鈴聲
      _playUnavailableTone();
      _startTimeout(); // 30 秒自動關閉
    } else {
      // ✅ 原本撥號流程（撥號 API、播放一般鈴聲、等待對方接聽…）
      _playRingtone();
      _initiateCall();
      _listenSignaling();
    }
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

  void _goMini() {
    CallOverlay.show(
      navigatorKey: rootNavigatorKey,
      child: MiniCallView(
        rootContext: rootNavigatorKey.currentContext!,
        roomId: _channelId ?? 'pending',
        isVoice: !widget.isVideoCall,
        remoteUid: _calleeUid,
        onExpand: () {
          CallOverlay.hide();
          Navigator.of(rootNavigatorKey.currentContext!).push(
            MaterialPageRoute(builder: (_) => CallRequestPage(
              broadcasterId: widget.broadcasterId,
              broadcasterName: widget.broadcasterName,
              broadcasterImage: widget.broadcasterImage,
              isBusy: widget.isBusy,
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
        flag: flag, // 1=視頻
        toUid: int.parse(widget.broadcasterId),
      );

      final Map<String, dynamic> data =
      (resp['data'] is Map) ? Map<String, dynamic>.from(resp['data']) : Map<String, dynamic>.from(resp);

      _channelId   = (data['channel_id'] ?? data['channel_name'] ?? data['channle_name'])?.toString();
      _callerToken = (data['string'] ?? data['token'])?.toString();
      _callerUid   = (data['from_uid'] as num?)?.toInt() ?? (data['uid'] as num?)?.toInt();
      _calleeUid   = (data['to_uid'] as num?)?.toInt();

      if (_channelId == null || _channelId!.isEmpty || _callerToken == null || _callerToken!.isEmpty) {
        throw '呼叫返回缺少必要欄位(channel/token)';
      }

      _startTimeout();
    } catch (e) {
      if (_cancelled) return;
      Fluttertoast.showToast(msg: "發起呼叫失敗：$e");
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

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () async {
      if (_cancelled) return;
      await _endWithToast(_kToastTimeout);
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
    // 先關掉小窗（若有）
    if (CallOverlay.isShowing) {
      CallOverlay.hide();
      // 等一幀防止 overlay 殘影
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    // 用 root navigator 清空堆疊回首頁
    final nav = Navigator.of(_rootCtx);
    nav.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
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
                        widget.isBusy ? '对方忙线中！' : '正在接通中...',
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
