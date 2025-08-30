import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class RtcEngineManager {
  static final RtcEngineManager _i = RtcEngineManager._();
  RtcEngineManager._();
  factory RtcEngineManager() => _i;

  late final RtcEngine _engine;
  bool _inited = false;
  bool _joined = false;
  bool _leaving = false;

  bool get isInited => _inited;
  bool get isJoined => _joined;

  Future<void> init(String appId) async {
    if (_inited) return;
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));
    await _engine.setLogLevel(LogLevel.logLevelInfo);

    // 跟著事件維護 _joined 狀態
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (_, __) => _joined = true,
      onLeaveChannel: (_, __) => _joined = false,
    ));

    _inited = true;
  }

  RtcEngine get engine {
    if (!_inited) {
      throw StateError('RtcEngineManager not initialized. Call init() first.');
    }
    return _engine;
  }

  Future<void> joinAs({
    required String channelId,
    required int uid,
    required String token,
    required ClientRoleType role,
  }) async {
    if (!_inited) throw StateError('RtcEngineManager not initialized.');
    await _engine.enableVideo();
    await _engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: role,
        publishCameraTrack: role == ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: role == ClientRoleType.clientRoleBroadcaster,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      ),
    );
    if (role == ClientRoleType.clientRoleBroadcaster) {
      await _engine.startPreview();
    }
  }

  Future<void> switchToBroadcaster() async {
    if (!_inited) return;
    await _engine.updateChannelMediaOptions(const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      publishCameraTrack: true,
      publishMicrophoneTrack: true,
    ));
    await _engine.startPreview();
  }

  Future<void> switchToAudience() async {
    if (!_inited) return;
    await _engine.updateChannelMediaOptions(const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleAudience,
      publishCameraTrack: false,
      publishMicrophoneTrack: false,
    ));
  }

  Future<void> leave() async {
    if (!_inited || !_joined || _leaving) return; // ✅ 沒初始化或沒進頻道就直接略過
    _leaving = true;
    try {
      await _engine.leaveChannel();
    } catch (_) {
      // 可忽略
    } finally {
      _leaving = false;
      _joined = false;
    }
  }

  Future<void> dispose() async {
    if (!_inited) return; // ✅ 未建立引擎直接略過
    try { await leave(); } catch (_) {}
    try { await _engine.release(); } catch (_) {}
    _inited = false;
  }
}