// 主播直播頁面

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../config/app_config.dart';

class BroadcasterPage extends StatefulWidget {
  const BroadcasterPage({super.key});

  @override
  State<BroadcasterPage> createState() => _BroadcasterPageState();
}

class _BroadcasterPageState extends State<BroadcasterPage> {
  String roomId = '';
  String title = '';
  String desc = '';
  String hostName = '';

  bool _isInitialized = false;
  bool _isEngineReady = false;
  late RtcEngine _engine;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        roomId = args['roomId'] ?? '';
        title = args['title'] ?? '';
        desc = args['desc'] ?? '';
        hostName = args['hostName'] ?? '';
        _isInitialized = true;
        _initAgora();
      } else {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    await WakelockPlus.enable();

    _engine = createAgoraRtcEngine();

    await _engine.initialize(RtcEngineContext(appId: AppConfig.agoraAppId));
    await _engine.setLogLevel(LogLevel.logLevelInfo);

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          print("✅ Broadcaster 加入成功 roomId = ${roomId} channel: ${connection.channelId}, uid: ${connection.localUid}");
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          print("👀 有人加入這個頻道 uid: $remoteUid");
          setState(() {});
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          print("🚪 有人離開了這個頻道 uid: $remoteUid");
          setState(() {});
        },
        onError: (ErrorCodeType code, String msg) {
          print("❗ Agora Error: $code - $msg");
          if (code == ErrorCodeType.errTokenExpired || code == ErrorCodeType.errInvalidToken) {
            _showTokenErrorDialog();
          }
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();

    try {
      await _engine.joinChannel(
        token: AppConfig.token,
        channelId: roomId,
        uid: 1000,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );
      print("📡 joinChannel() 呼叫成功");
    } catch (e) {
      print("❌ joinChannel 發生錯誤: $e");
    }

    setState(() {
      _isEngineReady = true;
    });
  }

  Future<void> _showTokenErrorDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Token 錯誤'),
        content: const Text('Token 已過期或無效，請重新取得。'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 關閉 dialog
              Navigator.of(context).pop(); // 離開頁面
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  Widget _renderLocalPreview() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || !_isEngineReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('直播中：$title')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('直播主：$hostName', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('直播介紹：$desc'),
              ],
            ),
          ),
          Expanded(child: _renderLocalPreview()),
        ],
      ),
    );
  }
}