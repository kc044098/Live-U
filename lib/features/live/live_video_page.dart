// 主播動態播放頁面
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../call/call_request_page.dart';

class LiveVideoPage extends StatefulWidget {
  final Map<String, String> user;

  const LiveVideoPage({super.key, required this.user});

  @override
  State<LiveVideoPage> createState() => _LiveVideoPageState();
}

class _LiveVideoPageState extends State<LiveVideoPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    final videoPath = widget.user['videoPath'] ?? 'assets/demo_video.mp4';
    if (videoPath.startsWith('http')) {
      _controller = VideoPlayerController.network(videoPath);
    } else if (videoPath.startsWith('/')) {
      _controller = VideoPlayerController.file(File(videoPath));
    } else {
      _controller = VideoPlayerController.asset(videoPath);
    }

    _controller.initialize().then((_) {
      setState(() {});
      _controller.play();
      _controller.setLooping(true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleCallRequest() {
    final broadcasterId = widget.user['broadcaster'] ?? '';
    final broadcasterName = widget.user['name'] ?? '主播';
    final broadcasterImage = widget.user['image'] ?? 'assets/default.jpg';

    // 🔰 假設目前使用者為撥打方
    const callerId = 'user_123';
    const callerName = 'Alex';
    const callerAvatar = 'assets/my_avatar.png';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallRequestPage(
          broadcasterId: broadcasterId,
          broadcasterName: broadcasterName,
          broadcasterImage: broadcasterImage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['name'] ?? '主播';
    final image = widget.user['image'] ?? '';
    final broadcasterId = widget.user['broadcaster'] ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.value.isInitialized
          ? Stack(
        children: [
          // 🎬 背景影片全螢幕播放
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),

          // 🔙 回上一頁
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 📞 通話請求按鈕
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            right: 16,
            child: GestureDetector(
              onTap: _handleCallRequest,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orangeAccent, Colors.purpleAccent],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.videocam, size: 20, color: Colors.white),
              ),
            ),
          ),

          // 👤 主播資訊欄
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage(image),
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        Text(
                          'Broadcaster ID: $broadcasterId',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}