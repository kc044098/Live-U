import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../data/network/avatar_cache.dart';
import '../mine/user_repository_provider.dart';

class ViewOtherImagePage extends ConsumerStatefulWidget {
  final String imagePath;
  final String? displayName;
  final String avatarPath;
  final String message;
  final bool isVip;
  final bool isLike;
  final int videoId;

  const ViewOtherImagePage({
    super.key,
    required this.imagePath,
    required this.displayName,
    required this.avatarPath,
    this.message = '',
    this.isVip = false,
    required this.isLike,
    required this.videoId,
  });

  @override
  ConsumerState<ViewOtherImagePage> createState() => _ViewOtherImagePageState();
}

class _ViewOtherImagePageState extends ConsumerState<ViewOtherImagePage>
    with SingleTickerProviderStateMixin {
  late bool isLiked;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    isLiked = widget.isLike;
  }

  void _onLikePressed() {
    setState(() {
      isLiked = !isLiked;
      _scale = 3.0; // 放大
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _scale = 1.0;
        });
      }
    });
    final svc = ref.read(backgroundApiServiceProvider);
    unawaited(
        svc.likeVideoAndRefresh(videoId: widget.videoId).catchError((e, st) {
        })
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// **全螢幕圖片**
          SizedBox.expand(
            child: CachedNetworkImage(
              imageUrl:widget.imagePath,
              fit: BoxFit.cover,
            ),
          ),

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
                          widget.displayName?? '',
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (widget.message.isNotEmpty)
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          /// **右下角愛心按鈕 + 動畫**
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


