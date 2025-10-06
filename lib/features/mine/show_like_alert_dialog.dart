import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/l10n.dart';
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
      ValueChanged<double>? onConfirmWithAmount,
    }) {
  final s = S.of(context);

  final Future<List<VipPlan>> futurePlans =
  ref.read(userRepositoryProvider).fetchVipPlans();

  final selectedIndexNotifier = ValueNotifier<int>(1);
  bool defaultFixed = false;
  List<VipPlan> cachedPlans = const [];

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
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.75,
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(s.whoLikesMe,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              s.likeDialogSubtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, color: Color(0xfffb5d5d)),
                            ),
                          ),
                          const SizedBox(height: 20),

                          FutureBuilder<List<VipPlan>>(
                            future: futurePlans,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(child: Text('${s.loadFailedPrefix}${snapshot.error}'));
                              }

                              final plans = snapshot.data ?? [];
                              cachedPlans = plans;

                              if (!defaultFixed) {
                                if (plans.length < 2) selectedIndexNotifier.value = 0;
                                defaultFixed = true;
                              }
                              if (plans.isEmpty) {
                                return Text(s.noPlansAvailable);
                              }

                              return GridView.builder(
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
                                              Text(
                                                s.usdPerMonth(p.perMonth.toStringAsFixed(2)),
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
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
                                child: Text(s.purchaseVip, style: const TextStyle(color: Colors.white)),
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

