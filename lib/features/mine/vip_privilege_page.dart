import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../profile/profile_controller.dart';
import '../wallet/payment_method_page.dart';

class VipPrivilegePage extends ConsumerStatefulWidget {
  const VipPrivilegePage({super.key});

  @override
  ConsumerState<VipPrivilegePage> createState() => _VipPrivilegePageState();
}

class _VipPrivilegePageState extends ConsumerState<VipPrivilegePage> {
  int selectedIndex = 1; // 預設選中中間方案（3個月）

  final List<Map<String, String>> plans = [
    {
      'title': '1个月',
      'price': '\$ 3.99',
      'original': '\$6.99',
      'perMonth': '\$ 3.99 / 月',
    },
    {
      'title': '3个月',
      'price': '\$ 10.77',
      'original': '\$20.99',
      'perMonth': '\$ 3.99 / 月',
      'tag': '最佳选择',
    },
    {
      'title': '6个月',
      'price': '\$ 19.15',
      'original': '\$32.88',
      'perMonth': '\$ 3.99 / 月',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VIP特权', style: TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🟣 會員特權區塊
            Container(
              width: double.infinity,
              height: 235,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/bg_vip.png'),
                  fit: BoxFit.fitWidth,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 10, top: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('會員特權',
                        style: TextStyle(fontSize: 28, color: Color(0xFF35012B))),
                    const SizedBox(height: 16),
                    const Text('解鎖特權，享頂級體驗',
                        style: TextStyle(fontSize: 14, color: Color(0xFF35012B))),
                    const SizedBox(height: 56),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: (user?.photoURL ?? '').startsWith('http')
                              ? Image.network(user!.photoURL!, width: 30, height: 30, fit: BoxFit.cover)
                              : Image.asset('assets/default_avatar.png', width: 30, height: 30, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 8),
                        Text(user?.displayName ?? '',
                            style: const TextStyle(fontSize: 14, color: Colors.black)),
                        const Spacer(),
                        user?.isVip == true
                            ? Text(
                          '2025-10-22 23:59:59 到期',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                        ): Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '暫未開通',
                            style: TextStyle(fontSize: 12, color: Colors.pinkAccent),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🟣 三個方案卡片
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(plans.length, (index) {
                final plan = plans[index];
                final selected = selectedIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => selectedIndex = index),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 115,
                        height: 120,
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFFFF5F5) : Colors.white,
                          border: Border.all(
                            color: selected ? Colors.red : const Color(0xFFE0E0E0),
                            width: selected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              plan['title']!,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plan['price']!,
                              style: const TextStyle(fontSize: 16, color: Colors.black),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '原价 ${plan['original']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              plan['perMonth']!,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      if (plan.containsKey('tag'))
                        Positioned(
                          top: -6,
                          left: 0,
                          child: Container(
                            width: 60,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF4D67),
                              borderRadius: BorderRadius.only(topRight: Radius.circular(8),topLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
                            ),
                            child: Text(
                              plan['tag']!,
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // 🟣 專屬特權清單
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '专属特权',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...[
                    {
                      'icon': 'assets/icon_vip_privilege1.svg',
                      'title': 'VIP尊享标识',
                      'desc': '点亮特权，让你成为与众不同的那颗心',
                    },
                    {
                      'icon': 'assets/icon_vip_privilege2.svg',
                      'title': '访问记录全解锁',
                      'desc': '不错过每个喜欢你的人',
                    },
                    {
                      'icon': 'assets/icon_vip_privilege3.svg',
                      'title': '无限制连线',
                      'desc': '无限连线，给你更多可能',
                    },
                    {
                      'icon': 'assets/icon_vip_privilege4.svg',
                      'title': '畅想直接私聊',
                      'desc': '免费无线私聊，随时发起',
                    },
                    {
                      'icon': 'assets/icon_vip_privilege5.svg',
                      'title': '高级美颜',
                      'desc': '特效更多，妆造更美丽帅气',
                    },
                  ].map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔴 粉紅圓背景 + SVG icon
                          Container(
                            width: 36,
                            height: 36,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEFEF),
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(item['icon']!, width: 20, height: 20),
                          ),
                          const SizedBox(width: 12),
                          // 文字區塊
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['desc']!,
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 20),
            // 🟣 購買按鈕
            if(user?.isVip == false)
              Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final priceText = plans[selectedIndex]['price']!;
                    final amount = double.tryParse(priceText.replaceAll('\$', '').trim()) ?? 0.0;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentMethodPage(amount: amount),
                      ),
                    );
                    user?.isVip = true;
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA06E), Color(0xFFDC5EF9)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: Text(
                        '${plans[selectedIndex]['price']!.replaceAll('\$', '').trim()} 美元 / ${plans[selectedIndex]['title']} 开通身份',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}