import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../config/app_config.dart';
import '../../core/ws/ws_provider.dart';
import '../../routes/app_routes.dart';
import '../call/call_repository.dart';
import '../profile/profile_controller.dart';

class BroadcasterPage extends ConsumerStatefulWidget {
  const BroadcasterPage({super.key});

  @override
  ConsumerState<BroadcasterPage> createState() => _BroadcasterPageState();
}

class _BroadcasterPageState extends ConsumerState<BroadcasterPage>
    with WidgetsBindingObserver {
  String roomId = '';
  String title = '';
  String desc = '';
  String? rtcToken;
  bool isCallMode = false;
  bool asBroadcaster = true;

  final List<int> _remoteUids = [];
  final List<VoidCallback> _wsUnsubs = [];

  bool _argsReady = false;
  bool _joined = false;
  bool _closing = false;
  RtcEngine? _engine;

  // 通話計時器
  Timer? _clockTimer;
  DateTime? _callStartAt;
  int _elapsedSec = 0;

  // PiP
  static const _pip = MethodChannel('pip');
  final GlobalKey _localPreviewKey = GlobalKey();

  // ----------------- 新結構 helpers（只看 data.*） -----------------
  Map<String, dynamic> _dataOf(Map p) =>
      (p['data'] is Map) ? Map<String, dynamic>.from(p['data']) : const {};
  String _ch(Map p) => _dataOf(p)['channel_id']?.toString() ?? '';
  int? _asInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '');
  int? _statusOf(Map p) => _asInt(_dataOf(p)['status']);

  bool _isThisChannel(Map p) => _ch(p) == roomId;

  // ---------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    debugPrint('📱[RTC] lifecycle=$state');
    final e = _engine;
    if (e == null) return;

    if (state == AppLifecycleState.paused) {
      // 問原生：是否在 PiP？若是，就不要停預覽/訂閱
      bool inPip = false;
      try { inPip = await _pip.invokeMethod('isInPiP') == true; } catch (_) {}
      if (!inPip) {
        // 你若想釋放相機，可開啟：
        // unawaited(e.stopPreview());
      }
    }

    if (state == AppLifecycleState.resumed) {
      _startClock();
      // 確保有訂閱遠端
      unawaited(e.muteAllRemoteVideoStreams(false));
      unawaited(e.muteAllRemoteAudioStreams(false));
      if (mounted) setState(() {}); // 重建 Texture 綁定
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _elapsedText {
    final s = _elapsedSec;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return (h > 0)
        ? '${_two(h)}:${_two(m)}:${_two(sec)}'
        : '${_two(m)}:${_two(sec)}';
  }

  void _startClock() {
    if (_clockTimer != null) return;
    _callStartAt ??= DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _callStartAt == null) return;
      final s = DateTime.now().difference(_callStartAt!).inSeconds;
      setState(() => _elapsedSec = s < 0 ? 0 : s);
    });
  }

  void _stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  Future<void> _endBecauseRemoteLeft() async {
    if (_closing) return;
    _closing = true;

    if (_joined) {
      Fluttertoast.showToast(msg: '對方已離開聊天室');
    }

    _stopClock();

    final e = _engine;
    _engine = null;
    if (e != null) {
      try { await e.leaveChannel(); } catch (_) {}
      try { await e.release(); } catch (_) {}
    }

    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(AppRoutes.home);
    }
  }

  // 手動進入 PiP（左上縮小鈕）
  Future<void> _enterPiP() async {
    if (!Platform.isAndroid) return;

    Rect? rect;
    final box = _localPreviewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final topLeft = box.localToGlobal(Offset.zero);
      rect = topLeft & box.size;
    }

    try {
      await _pip.invokeMethod('enterPiP', {
        'w': 9, 'h': 16,
        if (rect != null) 'left': rect.left.toInt(),
        if (rect != null) 'top': rect.top.toInt(),
        if (rect != null) 'width': rect.width.toInt(),
        if (rect != null) 'height': rect.height.toInt(),
      });
    } catch (e) {
      debugPrint('enterPiP error: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsReady) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    debugPrint('🎯[RTC] route args=$args');

    if (args is Map<String, dynamic>) {
      roomId        = (args['roomId'] ?? '').toString();
      title         = (args['title'] ?? '').toString();
      desc          = (args['desc'] ?? '').toString();
      rtcToken      = args['token'] as String?;
      isCallMode    = args['isCallMode'] == true;
      asBroadcaster = args['asBroadcaster'] != false;

      _argsReady = true;
      _initAgora();
      _listenCallSignals();
    } else {
      Navigator.of(context).pop();
    }
  }

  // === 只用新事件與新欄位 ===
  void _listenCallSignals() {
    final ws = ref.read(wsProvider);

    // 對方拒絕/結束：call.accept(status=2)
    _wsUnsubs.add(ws.on('call.accept', (p) {
      if (!_isThisChannel(p)) return;
      final st = _statusOf(p);
      if (st == 2) _endBecauseRemoteLeft();
    }));

    // 有些情況後端仍用 invite 通知結束（status=2/3/4）
    _wsUnsubs.add(ws.on('call.invite', (p) {
      if (!_isThisChannel(p)) return;
      final st = _statusOf(p);
      if (st == 2 || st == 3 || st == 4) _endBecauseRemoteLeft();
    }));

    // 若後端在通話中還會另外丟 end/timeout，就照 channel_id 收
    _wsUnsubs.add(ws.on('call.end', (p) { if (_isThisChannel(p)) _endBecauseRemoteLeft(); }));
    _wsUnsubs.add(ws.on('call.timeout', (p) { if (_isThisChannel(p)) _endBecauseRemoteLeft(); }));
    _wsUnsubs.add(ws.on('call.cancel', (p) { if (_isThisChannel(p)) _endBecauseRemoteLeft(); }));
  }

  Future<void> _initAgora() async {
    try {
      final pm = await [Permission.microphone, Permission.camera].request();
      debugPrint('🔐[RTC] mic=${pm[0]} cam=${pm[1]}');

      await WakelockPlus.enable();

      final engine = createAgoraRtcEngine();
      _engine = engine;
      debugPrint('🧠[RTC] engine instance=${identityHashCode(engine)}');

      await engine.initialize(RtcEngineContext(appId: AppConfig.agoraAppId));
      await engine.setLogLevel(LogLevel.logLevelInfo);

      engine.registerEventHandler(RtcEngineEventHandler(
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          print('👋 left, duration=${stats.duration}');
        },
        onError: (ErrorCodeType code, String msg) {
          debugPrint('❗[RTC] onError code=$code msg=$msg');
        },
        onRemoteVideoStateChanged: (RtcConnection c, int uid,
            RemoteVideoState st, RemoteVideoStateReason rsn, int elapsed) {
          debugPrint('📺[RTC] remote $uid state=$st reason=$rsn');
          if (st == RemoteVideoState.remoteVideoStateFrozen ||
              st == RemoteVideoState.remoteVideoStateStopped) {
            unawaited(_engine?.muteRemoteVideoStream(uid: uid, mute: false));
            if (mounted) setState(() {});
          }
        },
        onConnectionStateChanged: (RtcConnection c, ConnectionStateType s,
            ConnectionChangedReasonType r) {
          debugPrint('🌐[RTC] state=$s reason=$r');
        },
        onJoinChannelSuccess: (RtcConnection c, int elapsed) async {
          debugPrint('✅[RTC] onJoinChannelSuccess ch=${c.channelId} uid=${c.localUid}');
          _startClock();
          if (mounted) {
            setState(() {
              _joined = true;
            });
          }
          await _engine?.enableLocalVideo(true);
          await _engine?.muteLocalVideoStream(false);

          await _engine?.updateChannelMediaOptions(const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            publishCameraTrack: true,
            publishMicrophoneTrack: true,
            autoSubscribeVideo: true,
            autoSubscribeAudio: true,
          ));

          _setAutoPiP(true);
        },
        onUserJoined: (RtcConnection c, int uid, int elapsed) {
          debugPrint('👀[RTC] remote joined uid=$uid');
          if (!mounted) return;
          setState(() { if (!_remoteUids.contains(uid)) _remoteUids.add(uid); });
        },
        onUserOffline: (RtcConnection c, int uid, UserOfflineReasonType reason) async {
          debugPrint('👋[RTC] remote left uid=$uid reason=$reason');
          if (!mounted) return;
          setState(() { _remoteUids.remove(uid); });

          if (isCallMode && _remoteUids.isEmpty && !_closing) {
            await _endBecauseRemoteLeft();
          }
        },
        onFirstRemoteVideoFrame: (RtcConnection c, int uid, int w, int h, int e) {
          debugPrint('🎥 first remote frame uid=$uid ${w}x$h');
        },
        onFirstLocalVideoFrame: (src, w, h, _) => debugPrint('🎥 first local frame ${w}x$h'),
      ));

      await _engine!.setVideoEncoderConfiguration(VideoEncoderConfiguration(
        dimensions: const VideoDimensions(width: 540, height: 960),
        frameRate: 15,
        bitrate: 800, // kbps 初值，Agora 會自適應
        orientationMode: OrientationMode.orientationModeFixedPortrait,
      ));

      await engine.enableVideo();
      await engine.enableAudio();
      await engine.startPreview();

      final profile = isCallMode
          ? ChannelProfileType.channelProfileCommunication
          : ChannelProfileType.channelProfileLiveBroadcasting;

      final opts = ChannelMediaOptions(
        channelProfile: profile,
        clientRoleType: ClientRoleType.clientRoleBroadcaster, // Communication 下會被忽略，但留著無妨
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      );

      final mUser = ref.read(userProfileProvider);
      debugPrint('➡️[RTC] joinChannel(room="$roomId", uid=${mUser!.uid}, tokenLen=${rtcToken?.length}, role=${asBroadcaster ? 'broadcaster' : 'audience'})');

      await engine.joinChannel(
        token: rtcToken ?? '',
        channelId: roomId,
        uid: int.parse(mUser.uid),
        options: opts,
      );
    } catch (e, st) {
      debugPrint('💥[RTC] init error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('RTC 初始化失敗：$e')));
      Navigator.of(context).pop();
    }
  }

  Widget _buildRemoteView() {
    if (_engine == null || _remoteUids.isEmpty) {
      return const ColoredBox(color: Colors.black);
    }
    final remoteUid = _remoteUids.first;

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: remoteUid),
        connection: RtcConnection(channelId: roomId),
        useFlutterTexture: true,
        useAndroidSurfaceView: false,
      ),
    );
  }


  Widget _buildLocalViewMirrored() {
    if (_engine == null) return const SizedBox.shrink();
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(
          uid: 0,
          mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
        ),
        useFlutterTexture: true,
        useAndroidSurfaceView: false,
      ),
    );
  }

  Future<void> _setAutoPiP(bool enable) async {
    if (!Platform.isAndroid) return;

    Rect? rect;
    final box = _localPreviewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final topLeft = box.localToGlobal(Offset.zero);
      rect = topLeft & box.size;
    }

    try {
      await _pip.invokeMethod('armAutoPip', {
        'enable': enable,
        'w': 9, 'h': 16,
        if (rect != null) 'left': rect.left.toInt(),
        if (rect != null) 'top': rect.top.toInt(),
        if (rect != null) 'width': rect.width.toInt(),
        if (rect != null) 'height': rect.height.toInt(),
      });
    } catch (e) {
      debugPrint('armAutoPip error: $e');
    }
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;

    // 後端規定：離開也用 respondCall(flag=2)
    final repo = ref.read(callRepositoryProvider);
    unawaited(repo.respondCall(channelName: roomId, callId: null, accept: false,)
        .timeout(const Duration(seconds: 2), onTimeout: () => <String, dynamic>{})
        .then<void>((_) {}, onError: (e) {
          debugPrint('[hangup] notify fail: $e');
      }),
    );

    final e = _engine;
    _engine = null;
    if (e != null) {
      try { unawaited(e.leaveChannel()); } catch (_) {}
      try { unawaited(e.release()); } catch (_) {}
    }
    unawaited(WakelockPlus.disable());
    _stopClock();
    unawaited(_setAutoPiP(false));

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // 只做清理，不呼叫 _close()（避免二次 pop 與重複通知）
    _stopClock();
    unawaited(_setAutoPiP(false));
    for (final u in _wsUnsubs) { try { u(); } catch (_) {} }
    _wsUnsubs.clear();

    final e = _engine;
    _engine = null;
    if (e != null) {
      try { e.leaveChannel(); } catch (_) {}
      try { e.release(); } catch (_) {}
    }
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    if (!_argsReady || _engine == null || !_joined) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async { _close(); return false; },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 遠端畫面全屏
            Positioned.fill(child: _buildRemoteView()),

            // 左上：縮小（PiP）
            Positioned(
              top: top + 6, left: 12,
              child: IconButton(
                icon: Image.asset('assets/zoom.png', width: 20, height: 20),
                onPressed: _enterPiP,
                tooltip: '縮小畫面',
                splashRadius: 22,
              ),
            ),

            // 上方置中：對方名字
            Positioned(
              top: top + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  title.isEmpty ? '' : title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // 名字下方 計時膠囊
            Positioned(
              top: top + 56,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _joined ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.only(top: 4),
                    width: 120,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _elapsedText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 右上：白色 X 關閉
            Positioned(
              top: top + 6,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 22),
                onPressed: _close,
                tooltip: '關閉',
                splashRadius: 22,
              ),
            ),

            // 本地預覽：右側偏上（加陰影）
            Positioned(
              right: 12,
              top: top + 120,
              width: 120,
              height: 160,
              child: Container(
                key: _localPreviewKey,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildLocalViewMirrored(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}