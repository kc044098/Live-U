// 我喜歡的 頁面

import 'package:cached_network_image/cached_network_image.dart';
import 'package:djs_live_stream/features/mine/model/fan_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../data/network/background_api_service.dart';
import '../profile/profile_controller.dart';
import '../profile/view_profile_page.dart';
import 'member_focus_provider.dart';
import 'model/focus_user.dart';

class LikedUsersPage extends ConsumerStatefulWidget {
  const LikedUsersPage({super.key});

  @override
  ConsumerState<LikedUsersPage> createState() => _LikedUsersPageState();
}

class _LikedUsersPageState extends ConsumerState<LikedUsersPage> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();

    // 首次載入
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memberFocusProvider.notifier).loadFirstPage();
    });

    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      // 快到底再拉下一頁
      if (pos.pixels >= pos.maxScrollExtent - 300) {
        ref.read(memberFocusProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focus = ref.watch(memberFocusProvider);
    final cdn = ref.watch(userProfileProvider)?.cdnUrl ?? '';

    final isInitialLoading = focus.isLoading && focus.page == 0;
    final isEmpty = focus.items.isEmpty && !focus.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我喜欢的', style: TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(memberFocusProvider.notifier).refresh(),
        displacement: 64,
        color: Colors.black87,
        child: Builder(
          builder: (_) {
            if (isInitialLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 160),
                  Center(
                    child: Text('還沒有喜歡的人～', style: TextStyle(color: Colors.black54)),
                  ),
                ],
              );
            }

            // +1: 尾端 loading 卡片
            final total = focus.items.length + (focus.hasMore ? 1 : 0);

            return GridView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 60),
              physics: const AlwaysScrollableScrollPhysics(), // 列表不足一屏也可下拉
              itemCount: total,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.66,
              ),
              itemBuilder: (context, index) {
                // 尾端 loading 佔位
                if (index >= focus.items.length) {
                  return const _LoadingTile();
                }

                final u = focus.items[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ViewProfilePage(userId: u.id)),
                    );
                  },
                  child: _buildLikedCardFromApi(u, cdn),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // —— UI 外觀維持你的版本，只把 Asset 換成網路圖（相對路徑時拼 CDN）
  Widget _buildLikedCardFromApi(MemberFocusUser user, String cdnBase) {
    final coverRaw = user.avatars.firstNonEmptyOrEmpty();
    final coverUrl = joinCdnIfNeeded(coverRaw, cdnBase);

    final Widget image = (coverUrl.isNotEmpty && coverUrl.startsWith('http'))
        ? CachedNetworkImage(
      imageUrl: coverUrl,
      fit: BoxFit.cover,
      // 黑底載入 & 失敗
      placeholder: (_, __) => const ColoredBox(color: Colors.black),
      errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black12),
    )
        : Image.asset('assets/pic_girl1.png', fit: BoxFit.cover);

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 背景圖
            Positioned.fill(child: image),

            // 底部漸層 + 名稱 + 禮物
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        (user.name.isNotEmpty ? user.name : '用戶'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(blurRadius: 2, color: Colors.black45)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => Fluttertoast.showToast(msg: '你已贈送出禮物～'),
                      child: Image.asset(
                        'assets/pic_gift.png',
                        height: 28,
                        width: 28,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}