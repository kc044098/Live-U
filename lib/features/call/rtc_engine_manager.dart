import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class RtcEngineManager {
  static final RtcEngineManager _i = RtcEngineManager._();
  RtcEngineManager._();
  factory RtcEngineManager() => _i;

  late final RtcEngine _engine;
  bool _inited = false;

  Future<void> init(String appId) async {
    if (_inited) return;
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));
    await _engine.setLogLevel(LogLevel.logLevelInfo);
    _inited = true;
  }

  RtcEngine get engine => _engine;

  Future<void> joinAs({
    required String channelId,
    required int uid,
    required String token,
    required ClientRoleType role,
  }) async {
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
    await _engine.updateChannelMediaOptions(const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      publishCameraTrack: true,
      publishMicrophoneTrack: true,
    ));
    await _engine.startPreview();
  }

  Future<void> switchToAudience() async {
    await _engine.updateChannelMediaOptions(const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleAudience,
      publishCameraTrack: false,
      publishMicrophoneTrack: false,
    ));
  }

  Future<void> leave() async {
    await _engine.leaveChannel();
  }

  Future<void> dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
    _inited = false;
  }
}