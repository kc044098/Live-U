import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../wallet/payment_method_page.dart';
import 'model/vip_plan.dart';

final likeDialogSelectedPlanProvider = StateProvider<VipPlan?>((ref) => null);
void showLikeAlertDialog(
    BuildContext context,
    WidgetRef ref,
    VoidCallback onConfirm, {
      bool barrierDismissible = true,
      bool interceptBack = false,
      NavigatorState? pageContext,
      ValueChanged<double>? onConfirmWithAmount, // 帶出所選特價金額
    }) {
  // ✅ 只建立一次，之後不會因 setState 變動而重取
  final Future<List<VipPlan>> futurePlans =
  ref.read(userRepositoryProvider).fetchVipPlans();

  // ✅ 只讓「選中索引」驅動卡片重繪
  final selectedIndexNotifier = ValueNotifier<int>(1); // 預選第二個
  bool defaultFixed = false; // 首次拿到資料時，若不足兩個，改成 0
  List<VipPlan> cachedPlans = const []; // 確保按鈕能取到資料

  showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      return WillPopScope(
        onWillPop: () async {
          if (interceptBack && pageContext != null) {
            pageContext.pop();
            return false;
          }
          return true;
        },
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: Colors.transparent,
          child: SizedBox(
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
                    child: Image.asset('assets/message_like_2.png', width: 60, height: 60),
                  ),
// 🔽 用「最大高度 + 可捲動」包住原本的 Column
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      // 視需要微調 0.7~0.8
                      maxHeight: MediaQuery.of(context).size.height * 0.75,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('誰喜歡我',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

                          // ✅ 重點：移除原本的 SizedBox(height: 200)
                          FutureBuilder<List<VipPlan>>(
                            future: futurePlans,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(child: Text('載入失敗: ${snapshot.error}'));
                              }

                              final plans = snapshot.data ?? [];
                              cachedPlans = plans;

                              if (!defaultFixed) {
                                if (plans.length < 2) selectedIndexNotifier.value = 0;
                                defaultFixed = true;
                              }
                              if (plans.isEmpty) {
                                return const Text('暫無可用方案');
                              }

                              return GridView.builder(
                                // 讓 Grid 自己長高，由外層 ScrollView 捲動
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: plans.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.7,
                                ),
                                itemBuilder: (context, index) {
                                  final p = plans[index];
                                  return ValueListenableBuilder<int>(
                                    valueListenable: selectedIndexNotifier,
                                    builder: (_, selectedIndex, __) {
                                      final bool isSelected = index == selectedIndex;
                                      return GestureDetector(
                                        onTap: () => selectedIndexNotifier.value = index,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isSelected ? Colors.pink : Colors.transparent,
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(p.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.red)),
                                              const SizedBox(height: 4),
                                              Text('\$${p.price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                    decoration: TextDecoration.lineThrough,
                                                  )),
                                              const SizedBox(height: 4),
                                              Text('\$${p.payPrice.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      fontSize: 16, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 8),
                                              Text('${p.perMonth.toStringAsFixed(2)} 美元/月',
                                                  style: const TextStyle(
                                                      fontSize: 12, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
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
                                onPressed: () async {
                                  if (cachedPlans.isEmpty) return;
                                  final idx = selectedIndexNotifier.value.clamp(0, cachedPlans.length - 1);
                                  final amount = cachedPlans[idx].payPrice;

                                  if (onConfirmWithAmount != null) {
                                    onConfirmWithAmount(amount);
                                  } else {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PaymentMethodPage(amount: amount),
                                      ),
                                    );
                                  }
                                  onConfirm();
                                },
                                child: const Text('購買VIP', style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  ).then((_) {
    selectedIndexNotifier.dispose();
  });
}
