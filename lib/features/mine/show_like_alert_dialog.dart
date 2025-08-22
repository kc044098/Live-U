import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'model/vip_plan.dart';

void showLikeAlertDialog(
    BuildContext context,
    WidgetRef ref,
    VoidCallback onConfirm, {
      bool barrierDismissible = true,
      bool interceptBack = false,
      NavigatorState? pageContext,
    }) {
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: Colors.transparent,
          child: SizedBox( // 👉 讓整體更寬
            width: MediaQuery.of(context).size.width * 0.9,
            child: Container(
              padding: const EdgeInsets.all(16),
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

                      // 🔽 真數據方案清單
                      FutureBuilder<List<VipPlan>>(
                        future: ref.read(userRepositoryProvider).fetchVipPlans(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(child: Text('載入失敗: ${snapshot.error}'));
                          }

                          final plans = snapshot.data ?? [];
                          if (plans.isEmpty) {
                            return const Text('暫無可用方案');
                          }

                          return SizedBox( // 👉 固定清單區高度，避免超出
                            height: 200,
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: plans.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.78, // 👉 稍微加高每格
                              ),
                              itemBuilder: (context, index) {
                                final p = plans[index];
                                final oldPrice = p.price;     // 原價
                                final salePrice = p.payPrice; // 售價(特價或等於原價)

                                return Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        p.title, // 例如 "1个月" / "3个月"
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // ✅ 永遠顯示原價（刪除線）
                                      Text(
                                        '\$${oldPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      // 售價（特價或原價）
                                      Text(
                                        '\$${salePrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // 每月單價
                                      Text(
                                        '${p.perMonth.toStringAsFixed(2)} 美元/月',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),
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
                            child: const Text('購買VIP', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}