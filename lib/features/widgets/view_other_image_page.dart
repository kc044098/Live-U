import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../data/network/avatar_cache.dart';
import '../../l10n/l10n.dart';
import '../live/data_model/feed_item.dart';
import '../live/data_model/home_feed_state.dart';
import '../mine/user_repository_provider.dart';
import '../profile/profile_controller.dart';

class ViewOtherImagePage extends ConsumerStatefulWidget {
  final String imagePath;
  final String? displayName;
  final String avatarPath;
  final String message;
  final bool isVip;
  final bool isLike;
  final String uid;
  final bool isBroadcaster;
  final int isTop; // 1=精選, 2=日常（和你另一頁一致）

  const ViewOtherImagePage({
    super.key,
    required this.imagePath,
    required this.displayName,
    required this.avatarPath,
    this.message = '',
    this.isVip = false,
    required this.isLike,
    required this.uid,
    required this.isBroadcaster,
    required this.isTop,
  });

  @override
  ConsumerState<ViewOtherImagePage> createState() => _ViewOtherImagePageState();
}
class _ViewOtherImagePageState extends ConsumerState<ViewOtherImagePage>
    with SingleTickerProviderStateMixin {
  late bool isLiked;
  double _scale = 1.0;
  late final int _intUid;

  // 分類文字 → 改用多語系
  String _catText(int v) {
    final l = S.of(context);
    return v == 1 ? l.categoryFeatured : l.categoryDaily;
  }

  Color _catColor(int v) => v == 1 ? const Color(0xFFFF4D67) : const Color(0xFF3A9EFF);

  @override
  void initState() {
    super.initState();
    _intUid = int.tryParse(widget.uid) ?? -1;
    final likedFromList = _selectLikeFromHomeFeed(ref, _intUid);
    isLiked = likedFromList ?? widget.isLike;
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final latest = _selectLikeFromHomeFeed(ref, _intUid);
    if (latest != null && latest != isLiked) {
      setState(() => isLiked = latest);
    }
  }

  bool? _selectLikeFromHomeFeed(WidgetRef ref, int uid) {
    return ref.read(
      homeFeedProvider.select((s) {
        final hit = s.items.cast<FeedItem?>().firstWhere(
              (e) => e != null && e.uid == uid,
          orElse: () => null,
        );
        if (hit == null) return null;
        return hit.isLike == 1; // 1=已讚，其餘=未讚
      }),
    );
  }


  void _onLikePressed() {

    // 樂觀更新 + 小放大動畫
    setState(() {
      isLiked = !isLiked;
      _scale = 3.0;
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _scale = 1.0);
    });

    // 同步到首頁推薦列表（批量：該 uid 的所有卡片）
    ref.read(homeFeedProvider.notifier).setLikeByUser(
      uid: _intUid,
      liked: isLiked,
    );

    // 背景送 API；失敗回滾（UI + 列表）
    final svc = ref.read(backgroundApiServiceProvider);
    unawaited(
      svc.likeUserAndRefresh(targetUid: widget.uid).catchError((e, st) {
        if (!mounted) return;
        setState(() => isLiked = !isLiked); // UI 回滾
        ref.read(homeFeedProvider.notifier).setLikeByUser(
          uid: _intUid,
          liked: isLiked, // 回滾後的值
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(userProfileProvider)?.uid;
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
          ): SizedBox(height: 40),

          // 右下角分類膠囊（僅當擁有者是主播時顯示；不可點擊）
          if (widget.isBroadcaster)
            Positioned(
              bottom: 60,
              right: 16,
              child: IgnorePointer( // 不可點擊且保留顏色
                ignoring: true,
                child: ElevatedButton(
                  onPressed: () {}, // 不會被觸發（被 IgnorePointer 擋住）
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _catColor(widget.isTop),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text(
                    _catText(widget.isTop),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


