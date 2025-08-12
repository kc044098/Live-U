// 喜歡我的 頁面

import 'dart:ui';

import 'package:djs_live_stream/features/mine/show_like_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../profile/profile_controller.dart';
import '../profile/view_profile_page.dart';
import '../wallet/my_wallet_page.dart';
import '../wallet/payment_method_page.dart';
class WhoLikesMePage extends ConsumerStatefulWidget {
  const WhoLikesMePage({super.key});

  @override
  ConsumerState<WhoLikesMePage> createState() => _WhoLikesMePageState();
}

class _WhoLikesMePageState extends ConsumerState<WhoLikesMePage> {
  bool _showBlockLayer = false;

  @override
  void initState() {
    super.initState();

    // 延遲 1 秒後判斷是否為 VIP
    Future.delayed(const Duration(milliseconds: 500), () {
      final user = ref.read(userProfileProvider);
      if (mounted && user?.isVip != true) {
        setState(() {
          _showBlockLayer = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final likedUsers = [
      {'name': '漂亮的小姐姐 1', 'image': 'assets/pic_girl1.png'},
      {'name': '漂亮的小姐姐 2', 'image': 'assets/pic_girl2.png'},
      {'name': '漂亮的小姐姐 3', 'image': 'assets/pic_girl3.png'},
      {'name': '漂亮的小姐姐 4', 'image': 'assets/pic_girl4.png'},
      {'name': '漂亮的小姐姐 5', 'image': 'assets/pic_girl5.png'},
      {'name': '漂亮的小姐姐 6', 'image': 'assets/pic_girl6.png'},
    ];

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
          GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 60),
            itemCount: likedUsers.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.66,
            ),
            itemBuilder: (context, index) {
              final user = likedUsers[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewProfilePage(
                        userId: 1,
                      ),
                    ),
                  );
                },
                child: _buildLikedCard(user),
              );
            },
          ),

          // ✅ 覆蓋層：僅當非 VIP 且延遲後才顯示
          if (_showBlockLayer) _buildOverlayLayer(),
        ],
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

  Widget _buildLikedCard(Map<String, String> user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(user['image']!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(user['image']!),
              radius: 12,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(user['name']!, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 4),
            SvgPicture.asset('assets/logo_placeholder.svg', height: 28, width: 28),
          ],
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
