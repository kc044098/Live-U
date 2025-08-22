// 首頁 - 首頁 主播資訊的部分元件

import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../mine/user_repository_provider.dart';
import '../profile/profile_controller.dart';
import '../profile/view_profile_page.dart';
import 'data_model/home_feed_state.dart';

class LiveUserInfoCard extends ConsumerStatefulWidget {
  final int uid;
  final String name;
  final String? avatarPath;
  final String rateText;
  final List<String> tags;
  final int isLike;
  final void Function(bool liked)? onToggleLike;

  const LiveUserInfoCard( {
    super.key,
    required this.uid,
    required this.name,
    required this.avatarPath,
    required this.rateText,
    required this.tags,
    required this.isLike,
    required this.onToggleLike
  });

  @override
  ConsumerState<LiveUserInfoCard> createState() => _LiveUserInfoCardState();
}

class _LiveUserInfoCardState extends ConsumerState<LiveUserInfoCard> {
  bool isLiked = false;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    isLiked = widget.isLike == 1;
  }

  void _onLikePressed() {
    final next = !isLiked;
    setState(() {
      isLiked = next;
      _scale = 3.0;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _scale = 1.0;
        });
      }
    });

    widget.onToggleLike?.call(next);
  }

  // 重要：當 provider 的值改變時，讓本地也跟著同步
  @override
  void didUpdateWidget(covariant LiveUserInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLike != widget.isLike) {
      isLiked = widget.isLike == 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(userProfileProvider)?.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頭像 + 綠點
            Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewProfilePage(
                          userId: widget.uid,
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: (widget.avatarPath == null || widget.avatarPath!.isEmpty)
                        ? const AssetImage('assets/my_icon_defult.jpeg')
                        : CachedNetworkImageProvider(widget.avatarPath!) as ImageProvider,
                    radius: 24,
                  ),
                ),
                Positioned(
                  bottom: 3,
                  right: 3,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名字
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 金幣圖 + 價格 + 愛心
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/icon_gold1.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.rateText,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        (myUid != null && widget.uid.toString() != myUid) ?
                        GestureDetector(
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
                        ) : SizedBox(height: 40),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.tags.map((tag) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}