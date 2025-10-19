import 'dart:io';

import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:intl/intl.dart';
import '../../l10n/l10n.dart';
import '../profile/profile_controller.dart';
import '../wallet/iap_service.dart';
import '../wallet/payment_method_page.dart';
import '../wallet/wallet_repository.dart';
import 'model/vip_plan.dart';

// 你原本的 provider 不需改，保留可讓外部讀取選中的方案
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

  // ★ Android 的父訂閱商品（所有 base plan 都掛在這個下面）
  const String kAndroidVipParentProductId = 'vip__1m';

  // ---- 小工具：依平台決定查商店要用的 productId ----
  String _pidForQuery(VipPlan p) =>
      Platform.isAndroid ? kAndroidVipParentProductId : p.storeProductId;

  // ---- 小工具：讀取商店價（Android 走父商品 + base plan phase）----
  String? _storePriceForPlan(
      VipPlan p,
      Map<String, ProductDetails> productMap,
      ) {
    final key = Platform.isAndroid ? kAndroidVipParentProductId : p.storeProductId;
    final pd = productMap[key];
    if (pd == null) return null;

    if (!Platform.isAndroid) return pd.price; // iOS/一般直接用

    if (pd is! GooglePlayProductDetails) return pd.price;
    final offers = pd.productDetails.subscriptionOfferDetails;
    if (offers == null || offers.isEmpty) return pd.price;

    final offer = offers.firstWhere(
          (o) => o.basePlanId == p.androidBasePlanId,
      orElse: () => offers.first,
    );
    final phases = offer.pricingPhases;
    if (phases == null || phases.isEmpty) return pd.price;

    final phase = phases.first;

    // 有些 wrapper 會有 formattedPrice，優先用
    String? _tryGetFormattedPrice(dynamic phase) {
      try { return phase.formattedPrice as String?; } catch (_) { return null; }
    }
    final fp = _tryGetFormattedPrice(phase);
    if (fp != null && fp.isNotEmpty) return fp;

    final micros = (phase as dynamic).priceAmountMicros as int? ?? 0;
    final code   = (phase as dynamic).priceCurrencyCode as String? ?? '';
    if (micros <= 0 || code.isEmpty) return pd.price;

    final value = micros / 1000000.0;
    return NumberFormat.simpleCurrency(name: code).format(value);
  }

  // ---- 刷新 VIP 與錢包，更新到 userProfile ----
  Future<void> _refreshVipAndWallet() async {
    final walletRepo = ref.read(walletRepositoryProvider);
    final w = await walletRepo.fetchMoneyCash();
    final user = ref.read(userProfileProvider);
    if (user != null) {
      ref.read(userProfileProvider.notifier).state = user.copyWith(
        vipExpire: w.vipExpire,
        gold: w.gold,
      );
    }
  }

  // ---- 初始化：IAP 可用性 + 方案 +（視平台）商店商品 ----
  final Future<({
  bool iapReady,
  List<VipPlan> plans,
  Map<String, ProductDetails> productMap,
  int defaultIdx,
  int bestIdx,
  })> futureInit = () async {
    bool ready = false;
    try {
      await IapService.instance.init();
      ready = IapService.instance.isAvailable;
    } catch (_) {
      ready = false;
    }

    final userRepo = ref.read(userRepositoryProvider);
    final plans = await userRepo.fetchVipPlans();

    // 預設/最佳
    int bestIdx = 0;
    if (plans.isNotEmpty) {
      double bestPer = plans.first.perMonth;
      for (var i = 1; i < plans.length; i++) {
        if (plans[i].perMonth < bestPer) { bestPer = plans[i].perMonth; bestIdx = i; }
      }
    }
    final defaultIdx = (plans.length >= 2) ? 1 : (plans.isNotEmpty ? 0 : 0);

    // 查商店商品
    Map<String, ProductDetails> pMap = {};
    if (ready && plans.isNotEmpty) {
      final ids = Platform.isAndroid
          ? { kAndroidVipParentProductId }
          : plans.map((e) => e.storeProductId).where((s) => s.isNotEmpty).toSet();
      if (ids.isNotEmpty) {
        pMap = await IapService.instance.queryProducts(ids);
      }
    }

    return (iapReady: ready, plans: plans, productMap: pMap, defaultIdx: defaultIdx, bestIdx: bestIdx);
  }();

  // ---- 選中索引 / 購買中狀態 ----
  final selectedIndexNotifier = ValueNotifier<int>(1);
  final buyingVN = ValueNotifier<bool>(false);
  bool defaultFixed = false;

  // 👇 新增：前景回來時復位 buying 並刷新 VIP/錢包
  final _lifecycleObserver = _DialogLifecycleObserver(() {
    if (buyingVN.value) {
      debugPrint('[LikeDialog] app resumed while buying -> reset button');
      buyingVN.value = false;       // 讓購買按鈕恢復可按
      _refreshVipAndWallet();       // 順手拉一次狀態，避免漏單
    }
  });
  WidgetsBinding.instance.addObserver(_lifecycleObserver);

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
                          Text(s.whoLikesMe, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

                          FutureBuilder<({
                          bool iapReady,
                          List<VipPlan> plans,
                          Map<String, ProductDetails> productMap,
                          int defaultIdx,
                          int bestIdx,
                          })>(
                            future: futureInit,
                            builder: (context, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const Center(child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: CircularProgressIndicator(),
                                ));
                              }
                              if (snap.hasError) {
                                return Center(child: Text('${s.loadFailedPrefix}${snap.error}'));
                              }

                              final i = snap.data!;
                              final plans = i.plans;

                              // 設定預設選中一次
                              if (!defaultFixed) {
                                selectedIndexNotifier.value = i.defaultIdx;
                                defaultFixed = true;
                              }

                              if (plans.isEmpty) {
                                return Text(s.noPlansAvailable);
                              }

                              // Grid of plans（顯示商店價；沒有就顯示 payPrice）
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
                                  final storePrice = _storePriceForPlan(p, i.productMap);

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
                                              Text(
                                                storePrice ?? '\$${p.payPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
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
                              child: ValueListenableBuilder<bool>(
                                valueListenable: buyingVN,
                                builder: (_, buying, __) {
                                  return FutureBuilder<({
                                  bool iapReady,
                                  List<VipPlan> plans,
                                  Map<String, ProductDetails> productMap,
                                  int defaultIdx,
                                  int bestIdx,
                                  })>(
                                    future: futureInit,
                                    builder: (context, snap) {
                                      final disabled = buying || !snap.hasData || snap.data!.plans.isEmpty;
                                      return ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.pink,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        onPressed: disabled ? null : () async {
                                          final data = snap.data!;
                                          final plans = data.plans;
                                          final idx = selectedIndexNotifier.value.clamp(0, plans.length - 1);
                                          final sel = plans[idx];

                                          // 讓外部也能知道選了哪個（如果有在用這個 provider）
                                          ref.read(likeDialogSelectedPlanProvider.notifier).state = sel;

                                          // 沒開 IAP 就別走
                                          if (!data.iapReady) {
                                            Fluttertoast.showToast(msg: s.iapUnavailable);
                                            return;
                                          }

                                          // 取得父商品/對應商品
                                          Future<ProductDetails?> _ensurePd() async {
                                            final pid = _pidForQuery(sel);
                                            ProductDetails? pd = data.productMap[pid];
                                            if (pd != null) return pd;
                                            final map = await IapService.instance.queryProducts({pid});
                                            return map[pid];
                                          }

                                          buyingVN.value = true;
                                          try {
                                            if (Platform.isIOS) {
                                              final pd = await _ensurePd();
                                              if (pd == null) {
                                                Fluttertoast.showToast(msg: s.iapProductNotFound);
                                                return;
                                              }

                                              final purchase = await IapService.instance.buyNonConsumable(pd);
                                              final receipt = purchase.verificationData.serverVerificationData;

                                              await ref.read(walletRepositoryProvider).verifyIapAndCredit(
                                                platform: 'ios',
                                                productId: pd.id,
                                                packetId: sel.id,
                                                purchaseTokenOrReceipt: receipt,
                                              );

                                              await IapService.instance.finish(purchase);
                                              await _refreshVipAndWallet();
                                              Fluttertoast.showToast(msg: s.vipOpenSuccess);

                                              // 可選：外部 callback（舊參數相容）
                                              onConfirmWithAmount?.call(sel.payPrice);
                                              onConfirm();
                                              Navigator.of(context).pop();

                                              return;
                                            }

                                            if (Platform.isAndroid) {
                                              final pd = await _ensurePd(); // 父商品 vip__1m
                                              if (pd == null) {
                                                Fluttertoast.showToast(msg: s.iapProductNotFound);
                                                return;
                                              }
                                              final gp = pd as GooglePlayProductDetails;
                                              final offers = gp.productDetails.subscriptionOfferDetails;
                                              if (offers == null || offers.isEmpty) {
                                                Fluttertoast.showToast(msg: '此商品沒有可用的 Google Play plan');
                                                return;
                                              }

                                              final offer = offers.firstWhere(
                                                    (o) => o.basePlanId == sel.androidBasePlanId,
                                                orElse: () => offers.first,
                                              );
                                              final offerToken = offer.offerIdToken;
                                              if (offerToken == null || offerToken.isEmpty) {
                                                Fluttertoast.showToast(
                                                  msg: 'can not find Google Play base plan（${sel.androidBasePlanId}）',
                                                );
                                                return;
                                              }

                                              final purchase = await IapService.instance.buySubscription(
                                                pd, offerToken: offerToken,
                                              );
                                              final token = purchase.verificationData.serverVerificationData;

                                              await ref.read(walletRepositoryProvider).verifyIapAndCredit(
                                                platform: 'android',
                                                productId: pd.id,    // 父商品 vip__1m
                                                packetId: sel.id,    // 你的方案 id
                                                purchaseTokenOrReceipt: token,
                                              );

                                              await IapService.instance.finish(purchase);
                                              await _refreshVipAndWallet();
                                              Fluttertoast.showToast(msg: s.vipOpenSuccess);

                                              onConfirmWithAmount?.call(sel.payPrice);
                                              onConfirm();
                                              Navigator.of(context).pop();

                                              return;
                                            }

                                            Fluttertoast.showToast(msg: 'Unsupported platform');
                                                } catch (e) {
                                                  final isCanceled = e
                                                          is IapError &&
                                                      e.message == 'canceled';
                                                  if (isCanceled) {
                                                    Fluttertoast.showToast(
                                                      msg: s.commonCancel,
                                                    );
                                                  }
                                                } finally {
                                                  buyingVN.value = false;
                                                }
                                              },
                                        child: buying
                                            ? const SizedBox(
                                          width: 20, height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                            : Text(s.purchaseVip, style: const TextStyle(color: Colors.white)),
                                      );
                                    },
                                  );
                                },
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
    buyingVN.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver); // 👈 新增
  });
}

class _DialogLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onResumed;
  _DialogLifecycleObserver(this.onResumed);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}
