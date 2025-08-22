import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:video_player/video_player.dart';

import '../../data/network/avatar_cache.dart';
import '../live/data_model/feed_item.dart';
import '../live/data_model/home_feed_state.dart';
import '../mine/user_repository_provider.dart';
import '../profile/profile_controller.dart';

class ViewOtherVideoPage extends ConsumerStatefulWidget {
  final String videoPath;
  final String? displayName;
  final String avatarPath;
  final String message;
  final bool isVip;

  // ✅ 新增：按讚狀態 + 影片 id
  final bool isLike;
  final String uid;

  const ViewOtherVideoPage({
    super.key,
    required this.videoPath,
    required this.displayName,
    required this.avatarPath,
    this.message = '別睡了, 起來嗨',
    this.isVip = false,
    required this.isLike,
    required this.uid,
  });

  @override
  ConsumerState<ViewOtherVideoPage> createState() => _ViewOtherVideoPageState();
}

class _ViewOtherVideoPageState extends ConsumerState<ViewOtherVideoPage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool isLiked = false;
  double _scale = 1.0;
  late final int _intUid;

  @override
  void initState() {
    super.initState();
    _intUid = int.tryParse(widget.uid) ?? -1;
    final likedFromList = _selectLikeFromHomeFeed(ref, _intUid);
    isLiked = likedFromList ?? widget.isLike;

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

  /// 從首頁列表讀取某個 uid 的「是否被我按讚」
  bool? _selectLikeFromHomeFeed(WidgetRef ref, int uid) {
    final liked = ref.read(homeFeedProvider.select((s) {
        final hit = s.items.cast<FeedItem?>().firstWhere(
              (e) => e != null && e.uid == uid,
          orElse: () => null,
        );
        if (hit == null) return null;
        return hit.isLike == 1; // 你目前用 1=已讚 / 2/0=未讚
      }),
    );
    return liked;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 讓詳情頁在顯示中也能跟著首頁變化（例如從別處改了讚）
    final latest = _selectLikeFromHomeFeed(ref, _intUid);
    if (latest != null && latest != isLiked) {
      setState(() => isLiked = latest);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLikePressed() {
    // 動效
    setState(() {
      isLiked = !isLiked;
      _scale = 3.0;
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _scale = 1.0);
    });

    // 2) 先同步到首頁列表（樂觀）
    ref.read(homeFeedProvider.notifier)
        .setLikeByUser(uid: _intUid, liked: isLiked);

    // 3) 背景送 API；失敗回滾（UI + provider）
    final svc = ref.read(backgroundApiServiceProvider);
    unawaited(
        svc.likeUserAndRefresh(targetUid: widget.uid).catchError((e, st) {
          if (!mounted) return;
          // 回滾本地
          setState(() => isLiked = !isLiked);
          // 回滾首頁列表
          ref.read(homeFeedProvider.notifier)
              .setLikeByUser(uid: _intUid, liked: isLiked);
        })
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(userProfileProvider)?.uid;
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
                          backgroundImage: (widget.avatarPath == null || widget.avatarPath.isEmpty)
                              ? const AssetImage('assets/my_icon_defult.jpeg')
                              : CachedNetworkImageProvider(widget.avatarPath) as ImageProvider,
                          radius: 24,
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
          (myUid != null && widget.uid.toString() != myUid) ?
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
          ) : SizedBox(height: 40),
        ],
      ),
    );
  }
}