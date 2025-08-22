// 撥打電話端, 通常指的是用戶端

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
  String? rtcToken;
  int? myUid;
  bool isCallMode = false;
  bool asBroadcaster = true;

  final List<int> _remoteUids = [];

  bool _argsReady = false;
  bool _joined = false;
  RtcEngine? _engine;

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
      hostName      = (args['hostName'] ?? '').toString();
      rtcToken      = args['token'] as String?;
      myUid         = (args['uid'] as num?)?.toInt();
      isCallMode    = args['isCallMode'] == true;
      asBroadcaster = args['asBroadcaster'] != false;

      _argsReady = true;
      _initAgora();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _initAgora() async {
    try {
      final pm = await [Permission.microphone, Permission.camera].request();
      debugPrint('🔐[RTC] mic=${pm[0]} cam=${pm[1]}');

      await WakelockPlus.enable();

      final engine = createAgoraRtcEngine();
      _engine = engine;

      await engine.initialize(RtcEngineContext(appId: AppConfig.agoraAppId));
      await engine.setLogLevel(LogLevel.logLevelInfo);

      engine.registerEventHandler(RtcEngineEventHandler(
        onError: (ErrorCodeType code, String msg) {
          debugPrint('❗[RTC] onError code=$code msg=$msg');
        },
        onConnectionStateChanged: (RtcConnection c, ConnectionStateType s, ConnectionChangedReasonType r) {
          debugPrint('🌐[RTC] connection ch=${c.channelId} uid=${c.localUid} state=$s reason=$r');
        },
        onJoinChannelSuccess: (RtcConnection c, int elapsed) {
          debugPrint('✅[RTC] onJoinChannelSuccess ch=${c.channelId} uid=${c.localUid}');
          if (mounted) setState(() => _joined = true);
        },
        onUserJoined: (RtcConnection c, int uid, int elapsed) {
          debugPrint('👀[RTC] remote joined uid=$uid');
          if (!mounted) return;
          setState(() { if (!_remoteUids.contains(uid)) _remoteUids.add(uid); });
        },
        onUserOffline: (RtcConnection c, int uid, UserOfflineReasonType reason) {
          debugPrint('👋[RTC] remote left uid=$uid reason=$reason');
          if (!mounted) return;
          setState(() { _remoteUids.remove(uid); });
        },
      ));

      await engine.enableVideo();
      await engine.startPreview();

      final opts = ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: asBroadcaster
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        publishCameraTrack: asBroadcaster,
        publishMicrophoneTrack: asBroadcaster,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      );

      debugPrint('➡️[RTC] joinChannel(room="$roomId", uid=$myUid, tokenLen=${rtcToken?.length}, role=${asBroadcaster ? 'broadcaster' : 'audience'})');

      await engine.joinChannel(
        token: rtcToken ?? '',
        channelId: roomId,
        uid: myUid ?? 0,
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
      return const ColoredBox(color: Colors.black); // 沒有遠端畫面時的底色
    }
    final remoteUid = _remoteUids.first;
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine!,
        canvas: VideoCanvas(uid: remoteUid),
        connection: RtcConnection(channelId: roomId, localUid: myUid ?? 0),
      ),
    );
  }

  Widget _buildLocalViewMirrored() {
    if (_engine == null) return const SizedBox.shrink();
    // 用 Transform 做 UI 鏡像（只影響本地預覽，不影響實際上傳）
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
      child: AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      ),
    );
  }

  Future<void> _close() async {
    final e = _engine;
    _engine = null;
    if (e != null) {
      try { await e.leaveChannel(); } catch (_) {}
      try { await e.release(); } catch (_) {}
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    final e = _engine;
    _engine = null;
    if (e != null) {
      e.leaveChannel();
      e.release();
    }
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 遠端畫面全屏
          Positioned.fill(child: _buildRemoteView()),

          // 上方置中：對方名字（半透明膠囊）
          Positioned(
            top: top + 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title.isEmpty ? hostName : title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // 右上：白色 X 關閉
          Positioned(
            top: top + 6,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 22),
              onPressed: _close,
              tooltip: '關閉',
              splashRadius: 22,
            ),
          ),

          // 本地預覽：右側偏上（鏡像 + 圓角描邊）
          Positioned(
            right: 12,
            top: top + 80, // 靠中上
            width: 120,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildLocalViewMirrored(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}