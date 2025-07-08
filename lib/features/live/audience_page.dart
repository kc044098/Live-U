// 一般用戶進入直播觀看頁面

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../config/app_config.dart';

class AudiencePage extends StatefulWidget {
  final String roomId;
  final String title;
  final String desc;
  final String hostName;

  const AudiencePage({
    super.key,
    required this.roomId,
    required this.title,
    required this.desc,
    required this.hostName,
  });

  @override
  State<AudiencePage> createState() => _AudiencePageState();
}

class _AudiencePageState extends State<AudiencePage> {
  RtcEngine? _engine;
  final List<int> _remoteUids = [];
  bool _isJoined = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    await WakelockPlus.enable();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      RtcEngineContext(appId: AppConfig.agoraAppId),
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print("✅ Audience 加入成功 channel: ${connection.channelId}, uid: ${connection.localUid}");
          setState(() => _isJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print("👀 主播加入，uid: $remoteUid");
          setState(() => _remoteUids.add(remoteUid));
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          print("👋 主播離開 uid: $remoteUid");
          setState(() => _remoteUids.remove(remoteUid));
        },
        onError: (ErrorCodeType code, String msg) {
          print("❗ Audience Error: $code - $msg");
        },
      ),
    );

    await _engine!.enableVideo();

    await _engine!.joinChannel(
      token: '',
      channelId: widget.roomId,
      uid: 1,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      ),
    );
    print("📡 joinChannel() 呼叫成功");

    await _engine!.startPreview();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  Widget _buildRemoteVideo() {
    if (_remoteUids.isEmpty) {
      return const Center(
        child: Text("等待主播加入...", style: TextStyle(fontSize: 18)),
      );
    }

    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(
          uid: _remoteUids.first,
          mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
        ),
        connection: RtcConnection(channelId: widget.roomId, localUid: 1),
      ),
    );
  }

  Widget _buildLocalVideo() {
    if (!_isJoined || _remoteUids.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AgoraVideoView(
          controller: VideoViewController(
            rtcEngine: _engine!,
            canvas: const VideoCanvas(
              uid: 0,
              mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
            ),
          ),
        ),
      ),
    );
  }

  void _leaveChannel() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('觀眾視角：${widget.title}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '退出直播間',
            onPressed: _leaveChannel,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildRemoteVideo(),
          if (_isJoined)
            Positioned(
              bottom: 12,
              right: 12,
              width: 120,
              height: 160,
              child: _buildLocalVideo(),
            ),
        ],
      ),
    );
  }
}
