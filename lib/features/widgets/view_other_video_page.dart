import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:video_player/video_player.dart';

import '../../data/network/avatar_cache.dart';
import '../mine/user_repository_provider.dart';

class ViewOtherVideoPage extends ConsumerStatefulWidget {
  final String videoPath;
  final String? displayName;
  final String avatarPath;
  final String message;
  final bool isVip;

  // ✅ 新增：按讚狀態 + 影片 id
  final bool isLike;
  final int videoId;

  const ViewOtherVideoPage({
    super.key,
    required this.videoPath,
    required this.displayName,
    required this.avatarPath,
    this.message = '別睡了, 起來嗨',
    this.isVip = false,
    required this.isLike,
    required this.videoId,
  });

  @override
  ConsumerState<ViewOtherVideoPage> createState() => _ViewOtherVideoPageState();
}

class _ViewOtherVideoPageState extends ConsumerState<ViewOtherVideoPage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool isLiked = false;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    isLiked = widget.isLike;

    // ✅ 自動判斷來源（network / file / asset）
    final p = widget.videoPath;
    if (p.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(p));
    } else if (p.startsWith('file://') || File(p).existsSync()) {
      _controller = VideoPlayerController.file(
        File(p.startsWith('file://') ? Uri.parse(p).toFilePath() : p),
      );
    } else {
      _controller = VideoPlayerController.asset(p);
    }

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});           // 顯示第一幀
      _controller.setLooping(true);
      _controller.play();        // 自動播放，無暫停手勢
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLikePressed() {
    // 1) 動效 + 樂觀切換
    setState(() {
      isLiked = !isLiked;
      _scale = 3.0;
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _scale = 1.0);
    });

    // 2) 背景打 API（失敗還原）
    final svc = ref.read(backgroundApiServiceProvider);
    unawaited(
      svc.likeVideoAndRefresh(videoId: widget.videoId).catchError((e, st) {
        if (!mounted) return;
        setState(() {
          isLiked = !isLiked; // 還原
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// **全螢幕影片**
          if (_controller.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover, // 維持比例鋪滿，裁切不變形
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          /// **返回鍵**
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          /// **左下角使用者資訊與訊息**
          Positioned(
            left: 16,
            right: 16,
            bottom: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: buildAvatarProvider(
                            avatarUrl: widget.avatarPath,
                            context: context,
                            logicalSize: 48,
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Text(
                          widget.displayName ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (widget.isVip)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                              ),
                            ),
                            child: const Text(
                              'VIP',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (widget.message.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.message,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ),

          /// **右下角愛心按鈕 + 動畫（樂觀切換 + 背景送讚）**
          Positioned(
            bottom: 120,
            right: 20,
            child: GestureDetector(
              onTap: _onLikePressed,
              child: AnimatedScale(
                scale: _scale,
                duration: const Duration(milliseconds: 150),
                child: SvgPicture.asset(
                  isLiked
                      ? 'assets/live_heart_filled.svg'
                      : 'assets/live_heart.svg',
                  width: 40,
                  height: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}