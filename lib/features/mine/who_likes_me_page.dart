// 喜歡我的 頁面

import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../data/network/background_api_service.dart';
import '../call/call_request_page.dart';
import '../profile/profile_controller.dart';
import '../profile/view_profile_page.dart';
import '../wallet/payment_method_page.dart';
import 'member_fans_provider.dart';
import 'model/fan_user.dart';

class WhoLikesMePage extends ConsumerStatefulWidget {
  const WhoLikesMePage({super.key});

  @override
  ConsumerState<WhoLikesMePage> createState() => _WhoLikesMePageState();
}

class _WhoLikesMePageState extends ConsumerState<WhoLikesMePage> {
  bool _showBlockLayer = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();

    // 進頁面抓第一頁
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memberFansProvider.notifier).loadFirstPage();
    });

    // 非 VIP 遮罩
    Future.delayed(const Duration(milliseconds: 500), () {
      final user = ref.read(userProfileProvider);
      if (user?.isVip != true) {
        setState(() => _showBlockLayer = true);
      }
    });

    // 無限滾動載入下一頁（邏輯不影響既有 UI）
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      if (pos.pixels >= pos.maxScrollExtent - 300) {
        ref.read(memberFansProvider.notifier).loadNextPage();
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
    final fans = ref.watch(memberFansProvider);          // ← 改用 provider
    final cdn = ref.watch(userProfileProvider)?.cdnUrl ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('谁喜欢我', style: TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Grid 邏輯與樣式維持不變，只換資料來源
          GridView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 60),
            itemCount: fans.items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.66,
            ),
            itemBuilder: (context, index) {
              final u = fans.items[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // 用後端回來的 id 導到個資頁
                      builder: (_) => ViewProfilePage(userId: u.id),
                    ),
                  );
                },
                child: _buildLikedCardFromApi(u, cdn),
              );
            },
          ),

          // 非 VIP 遮罩（保留你的邏輯）
          if (_showBlockLayer)_buildOverlayLayer(),
        ],
      ),
    );
  }

  Widget _buildLikedCardFromApi(MemberFanUser user, String cdnBase) {
    // 封面：相對路徑才拼 CDN，取第一張非空
    final coverRaw = user.avatars.firstWhere((e) => e.isNotEmpty, orElse: () => '');
    final coverUrl = joinCdnIfNeeded(coverRaw, cdnBase);

    final image = (coverUrl.isNotEmpty && coverUrl.startsWith('http'))
        ? CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover)
        : Image.asset('assets/pic_girl1.png', fit: BoxFit.cover); // fallback

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 背景大圖
            Positioned.fill(child: image),

            // 底部漸層 + 名字 + 禮物圖示
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
                  children: [
                    Expanded(
                      child: Text(
                        user.name.isNotEmpty ? user.name : '用戶',
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
                        onTap: () => _handleCallRequest(context, user),
                        child: SvgPicture.asset('assets/logo_placeholder.svg',
                            height: 28, width: 28, fit: BoxFit.contain))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _handleCallRequest(BuildContext context, MemberFanUser user) {
    final broadcasterId = user.id.toString();
    final broadcasterName = user.name;
    final broadcasterImage = user.avatars.first;

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

  Widget _buildOverlayLayer() {
    return Stack(
      children: [
        // 霧化背景
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.6),
          ),
        ),

        // 半透明漸層遮罩 + 彈窗內容
        Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC3C3), Color(0xFFFFEFEF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('誰喜歡我', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text(
                  '查看對你心動的Ta，立即聯繫不再等待',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Color(0xfffb5d5d)),
                ),
                const SizedBox(height: 20),
                _getSubscriptionPlan(),
                const SizedBox(height: 20),
                SizedBox(
                  width: 180,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodPage(amount: 10.77)));

                      Navigator.pop(context, true);
                    },
                    child: const Text('購買VIP', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _getSubscriptionPlan() {
    final plans = [
      {'title': '1个月', 'price': '\$3.99', 'oldPrice': '', 'monthly': '3.99美元/月'},
      {'title': '3个月', 'price': '\$10.77', 'oldPrice': '\$11.97', 'monthly': '10.77美元/月'},
      {'title': '6个月', 'price': '\$19.15', 'oldPrice': '\$23.94', 'monthly': '19.15美元/月'},
      {'title': '1年', 'price': '\$33.5', 'oldPrice': '\$47.8', 'monthly': '10.77美元/月'},
      {'title': '订阅包月', 'price': '\$9', 'oldPrice': '\$10', 'monthly': '9美元/月'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plans.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final plan = plans[index];
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(plan['title']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
              if (plan['oldPrice']!.isNotEmpty)
                Text(plan['oldPrice']!, style: const TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.lineThrough)),
              const SizedBox(height: 2),
              Text(plan['price']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(plan['monthly']!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}
