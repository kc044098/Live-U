import 'package:flutter/material.dart';

void showLikeAlertDialog(BuildContext context, VoidCallback onConfirm, {
  bool barrierDismissible = true, bool interceptBack = false, NavigatorState? pageContext,}) {
  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      return WillPopScope(
          onWillPop: () async {
            if (interceptBack && pageContext != null) {
              pageContext.pop(); // ✅ 直接 pop page
              return false; // 不讓 dialog 自己關掉
            }
            return true;
          },
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC3C3), Color(0xFFFFEFEF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/message_like_2.png',
                    width: 60,
                    height: 60,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '誰喜歡我',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        '查看對你心動的Ta，立即聯繫不再等待',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Color(0xfffb5d5d)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _getSubscriptionPlan(),
                    const SizedBox(height: 10),
                    Center(
                      child: SizedBox(
                        width: 180,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: onConfirm,
                          child: const  Text('購買VIP', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _getSubscriptionPlan() {
  final List<Map<String, String>> _plans = [
    {
      'title': '1个月',
      'price': '\$3.99',
      'oldPrice': '',
      'monthly': '3.99美元/月',
    },
    {
      'title': '3个月',
      'price': '\$10.77',
      'oldPrice': '\$11.97',
      'monthly': '10.77美元/月',
    },
    {
      'title': '6个月',
      'price': '\$19.15',
      'oldPrice': '\$23.94',
      'monthly': '19.15美元/月',
    },
    {
      'title': '1年',
      'price': '\$33.5',
      'oldPrice': '\$47.8',
      'monthly': '10.77美元/月',
    },
    {
      'title': '订阅包月',
      'price': '\$9',
      'oldPrice': '\$10',
      'monthly': '9美元/月',
    },
  ];

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _plans.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
    ),
    itemBuilder: (context, index) {
      final plan = _plans[index];
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              plan['title']!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            if (plan['oldPrice']!.isNotEmpty) ...[
              Text(
                plan['oldPrice']!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
            const SizedBox(height: 2),
            Text(
              plan['price']!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              plan['monthly']!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    },
  );
}
