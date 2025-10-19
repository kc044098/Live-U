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

import '../../core/error_handler.dart';
import '../../core/ws/ws_provider.dart';
import '../../globals.dart';
import '../../l10n/l10n.dart';
import '../../routes/app_routes.dart' hide routeObserver;
import '../live/data_model/call_overlay.dart';
import '../live/mini_call_view.dart';
import '../profile/profile_controller.dart';
import '../widgets/tools/mic_cam_helper.dart';
import 'call_repository.dart';

import 'package:flutter_svg/flutter_svg.dart';

enum CalleeState { online, busy, offline }

class CallRequestPage extends ConsumerStatefulWidget {
  final String broadcasterId;
  final String broadcasterName;
  final String broadcasterImage;
  final bool isVideoCall;
  final CalleeState calleeState;

  final int? videoId;

  const CallRequestPage({
    super.key,
    required this.broadcasterId,
    required this.broadcasterName,
    required this.broadcasterImage,
    this.isVideoCall = true,
    this.videoId,
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

  String? _channelId;
  String? _callerToken;
  int? _callerUid;
  int? _calleeUid;

  bool _finished = false;
  bool _cancelled = false;
  bool _sentCancel = false;
  int _freeAtSec = 0;

  bool _inMini = false;

  String _statusText = '';
  bool _ringtoneStarted = false;
  bool _busyStarted = false;

  // 改為 getter：依目前語系取字串
  String get _kToastTimeout => S.of(_rootCtx).callTimeoutNoResponse;

  BuildContext get _rootCtx =>
      rootNavigatorKey.currentContext ?? Navigator.of(context, rootNavigator: true).context;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _statusText = S.of(_rootCtx).statusConnecting;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kickoffFlow();
    });
  }

  void _kickoffFlow() {
    _startDialFlow();
  }

  Future<void> _startDialFlow() async {
    final ok = await ensureMicCamForCall(
      context: context,
      isVideo: widget.isVideoCall == true,
    );
    if (!mounted) return;
    if (!ok) {
      Fluttertoast.showToast(msg: S.of(context).needMicCamPermission);
      return;
    }

    await _playRingtone();
    if (!mounted) return;

    _initiateCall();
    _listenSignaling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_cancelled && !_sentCancel) {
      unawaited(_notifyCancelOnce());
    }
    _timeoutTimer?.cancel();
    for (final u in _wsUnsubs) { try { u(); } catch (_) {} }
    _wsUnsubs.clear();

    unawaited(_safeStop(_audioPlayer, started: _ringtoneStarted));
    unawaited(_safeStop(_busyPlayer, started: _busyStarted));
    unawaited(_safeDispose(_audioPlayer));
    unawaited(_safeDispose(_busyPlayer));

    WakelockPlus.disable();
    super.dispose();
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
      ),
    );
    Navigator.of(rootNavigatorKey.currentContext!).pushNamed(AppRoutes.home);
  }


  Future<void> _playRingtone() async {
    try {
      await Future.delayed(const Duration(milliseconds: 50)); // 不要太久，縮短競態窗口
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('ringtone.wav'));  // 確認檔案在 assets/ 下
      _ringtoneStarted = true;
    } catch (_) {
      _ringtoneStarted = false; // 建立失敗就別再 stop
    }
  }

  Future<void> _safeStop(AudioPlayer p, {required bool started}) async {
    if (!started) return;
    try { await p.stop(); } catch (_) {}
  }

  Future<void> _safeDispose(AudioPlayer p) async {
    try { await p.dispose(); } catch (_) {}
  }

  Future<void> _initiateCall() async {
    try {
      await [Permission.microphone, Permission.camera].request();
      await WakelockPlus.enable();

      final flag = widget.isVideoCall ? 1 : 2;

      final data = await ref.read(callRepositoryProvider).liveCall(
        flag: flag,
        toUid: int.parse(widget.broadcasterId),
        videoId: widget.videoId,
      );

      final Map<String, dynamic> m =
      (data is Map) ? Map<String, dynamic>.from(data) : <String, dynamic>{};

      _channelId   = (m['channel_id'] ?? m['channel_name'] ?? m['channle_name'])?.toString();
      _callerToken = (m['string'] ?? m['token'])?.toString();
      _callerUid   = (m['from_uid'] as num?)?.toInt() ?? (m['uid'] as num?)?.toInt();
      _calleeUid   = (m['to_uid'] as num?)?.toInt();

      final fa = m['free_at'];
      _freeAtSec = (fa is num) ? fa.toInt() : int.tryParse(fa?.toString() ?? '') ?? 0;

      if (_channelId == null || _channelId!.isEmpty) {
        throw ApiException(-1, '電話撥打失敗：channelId 空');
      }
      if (_callerToken == null || _callerToken!.isEmpty) {
        throw ApiException(-1, '電話撥打失敗：token 空');
      }

      _startTimeout();
    } on ApiException catch (e) {
      final t = S.of(_rootCtx);
      if (e.code == 102) {
        Fluttertoast.showToast(msg: t.balanceNotEnough);
      } else if (e.code == 121) {
        Fluttertoast.showToast(msg: t.calleeBusy);
      } else if (e.code == 123) {
        Fluttertoast.showToast(msg: t.calleeOffline);
      } else if (e.code == 125) {
        Fluttertoast.showToast(msg: t.calleeDndOn);
      } else {
        AppErrorToast.show(e);
      }
      unawaited(_safeStop(_audioPlayer, started: _ringtoneStarted));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: S.of(_rootCtx).callDialFailed);
      unawaited(_safeStop(_audioPlayer, started: _ringtoneStarted));
      if (mounted) Navigator.pop(context);
    }
  }

  Map<String, dynamic> _dataOf(Map p) =>
      (p['data'] is Map) ? Map<String, dynamic>.from(p['data']) : const {};
  int? _asInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '');
  String _ch(Map p) => _dataOf(p)['channel_id']?.toString() ?? '';
  int? _status(Map p) => _asInt(_dataOf(p)['status']);
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

      if (CallOverlay.isShowing) {
        CallOverlay.hide();
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }

      final myName = ref.read(userProfileProvider)?.displayName ?? '';

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
          'callFlag'     : callFlag,
          'peerAvatar'   : widget.broadcasterImage,
          'free_at'      : _freeAtSec,
        },
      );
    }

    _wsUnsubs.add(ws.on('call.accept', (p) async {
      if (_cancelled || !_sameCall(p)) return;
      final st = _status(p);
      if (st == 1) {
        final peerFlag = _flagOf(p);
        final myPrefVideo = widget.isVideoCall;
        final wantVideo = myPrefVideo && (peerFlag == 1);
        final int callFlag = wantVideo ? 1 : 2;
        await _goToRoom(callFlag: callFlag);
      } else if (st == 2) {
        await _endWithToast(S.of(_rootCtx).peerDeclined);
      }
    }));

    _wsUnsubs.add(ws.on('call.invite', (p) async {
      if (_cancelled || !_sameCall(p)) return;
      if (_status(p) == 2) await _endWithToast(S.of(_rootCtx).peerDeclined);
    }));
  }

  void _startTimeout({ String? toast}) {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () async {
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

    unawaited(_safeStop(_audioPlayer, started: _ringtoneStarted));
    unawaited(_safeStop(_busyPlayer, started: _busyStarted));
    unawaited(_rtc.safeLeave().timeout(const Duration(seconds: 2), onTimeout: () {}));

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
    } catch (_) {}
  }

  Future<void> _cancelByUser() async {
    if (_finished) return;
    _finished = true;
    _cancelled = true;

    _timeoutTimer?.cancel();
    unawaited(_safeStop(_audioPlayer, started: _ringtoneStarted));
    unawaited(_safeStop(_busyPlayer, started: _busyStarted));
    unawaited(_notifyCancelOnce().timeout(const Duration(seconds: 2), onTimeout: () {}));
    unawaited(_rtc.safeLeave().timeout(const Duration(seconds: 2), onTimeout: () {}));

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
    final t = S.of(_rootCtx);
    switch (s) {
      case CalleeState.busy:    return t.statusBusy;
      case CalleeState.offline: return t.statusOffline;
      case CalleeState.online:  return t.statusConnecting;
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
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _statusText.isEmpty ? S.of(_rootCtx).statusConnecting : _statusText, // 👈 永遠顯示接通中
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

            Positioned(
              top: top + 8, left: 8,
              child: IconButton(
                icon: Image.asset('assets/zoom.png', width: 20, height: 20),
                onPressed: _goMini,
                tooltip: S.of(context).minimizeTooltip,
                splashRadius: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}