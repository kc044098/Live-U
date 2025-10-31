import 'dart:io';

import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart'
    show PricingPhaseWrapper;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../profile/profile_controller.dart';
import '../wallet/iap_service.dart';
import '../wallet/wallet_repository.dart';
import 'model/vip_plan.dart';

class VipPrivilegePage extends ConsumerStatefulWidget {
  const VipPrivilegePage({super.key});

  @override
  ConsumerState<VipPrivilegePage> createState() => _VipPrivilegePageState();
}

class _VipPrivilegePageState extends ConsumerState<VipPrivilegePage>
    with WidgetsBindingObserver {
  int selectedIndex = 0; // 由 API 回來後再決定預設
  List<VipPlan> _plans = const [];
  bool _loading = true;
  String? _error;
  int _bestIndex = 0; // 標示「最佳選擇」
  bool _buying = false;

// === IAP 相關 ===
  bool _iapReady = false;
  Map<String, ProductDetails> _productMap = {}; // productId -> ProductDetails
  String? _iapWarn;

  static const String kAndroidVipParentProductId = 'vip__1m';

// 2) 你頁面裡的這行改掉：
  String kGetPid(VipPlan p) {
    if (Platform.isAndroid) {
      return kAndroidVipParentProductId;
    }
    return p.storeProductId; // iOS 照舊
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initIap().then((_) => _loadPlans());
  }

  Future<void> _initIap() async {
    debugPrint('init()...');
    try {
      await IapService.instance.init();
      setState(() => _iapReady = IapService.instance.isAvailable);
      debugPrint('isAvailable = $_iapReady');
    } catch (e, st) {
      debugPrint('init FAILED: $e\n$st');
      setState(() => _iapReady = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 使用者可能剛關掉 Google Play 視窗或返回 App
      if (mounted && _buying) {
        debugPrint('[VIP] app resumed while buying -> reset button');
        setState(() => _buying = false);   // 👈 讓按鈕立即可按
        _refreshVipAndWallet();            // 👈 順便拉一次後端，避免漏單
      }
    }
  }

  Future<void> _loadPlans() async {
    setState(() { _loading = true; _error = null; });
    debugPrint('fetchVipPlans()...');
    try {
      final repo = ref.read(userRepositoryProvider);
      final plans = await repo.fetchVipPlans();

      debugPrint('plans = ${plans.length}');
      for (final p in plans) {
        debugPrint(' - ${p.title} id=${p.id} pid=${p.storeProductId} price=${p.price} payPrice=${p.payPrice}');
      }

      if (!mounted) return;

      if (plans.isEmpty) {
        debugPrint('No plans from backend');
        setState(() { _plans = const []; selectedIndex = 0; _bestIndex = 0; _loading = false; });
        return;
      }

      // 預設與最佳索引（保留原邏輯）
      int defaultIdx = plans.indexWhere((p) => p.month == 3);
      if (defaultIdx < 0) {
        double best = double.infinity;
        for (var i = 0; i < plans.length; i++) {
          final pm = plans[i].perMonth;
          if (pm < best) { best = pm; defaultIdx = i; }
        }
        if (defaultIdx < 0) defaultIdx = 0;
      }
      int bestIdx = 0;
      double bestPer = plans.first.perMonth;
      for (var i = 1; i < plans.length; i++) {
        if (plans[i].perMonth < bestPer) { bestPer = plans[i].perMonth; bestIdx = i; }
      }
      debugPrint('defaultIdx=$defaultIdx bestIdx=$bestIdx');

      // 查商店商品
      Map<String, ProductDetails> pMap = {};
      String? iapWarn;
      if (_iapReady) {
        final ids = plans.map((e) => kGetPid(e)).where((s) => s.isNotEmpty).toSet();
        debugPrint('queryProducts with ids=$ids');
        if (ids.isNotEmpty) {
          pMap = await IapService.instance.queryProducts(ids);
          debugPrint('queryProducts returned ${pMap.length} items');
          if (pMap.isEmpty) iapWarn = 'Store returned no matching products';
        } else {
          iapWarn = 'No productId from backend';
          debugPrint('WARN: $iapWarn');
        }
      } else {
        iapWarn = 'IAP not available';
        debugPrint('WARN: $iapWarn');
      }

      setState(() {
        _plans = plans;
        selectedIndex = defaultIdx;
        _bestIndex = bestIdx;
        _loading = false;
        _productMap = pMap;
        _iapWarn = iapWarn;
      });
    } catch (e, st) {
      debugPrint('fetchVipPlans FAILED: $e\n$st');
      if (!mounted) return;
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  String? _storePriceForPlan(VipPlan p) {
    final pd = _productMap[kGetPid(p)];
    if (pd == null) return null;

    // iOS 或一般（非 Android 訂閱）
    if (!Platform.isAndroid) return pd.price;

    if (pd is! GooglePlayProductDetails) return pd.price;

    final offers = pd.productDetails.subscriptionOfferDetails;
    if (offers == null || offers.isEmpty) return pd.price;

    final offer = offers.firstWhere(
          (o) => o.basePlanId == p.androidBasePlanId,   // <- 你的後端要提供這個欄位
      orElse: () => offers.first,
    );

    final List<PricingPhaseWrapper>? phases = offer.pricingPhases;
    if (phases == null || phases.isEmpty) return pd.price;

    final phase = phases.first;

    // 一些版本有 formattedPrice，就直接用
    final fp = (tryGetFormattedPrice(phase));
    if (fp != null && fp.isNotEmpty) return fp;

    // 沒有 formattedPrice 就用 micros + 幣別自己排
    final micros = phase.priceAmountMicros ?? 0;
    final code   = phase.priceCurrencyCode ?? '';
    if (micros <= 0 || code.isEmpty) return pd.price;

    final value = micros / 1000000.0;
    return NumberFormat.simpleCurrency(name: code).format(value);
  }

  String? tryGetFormattedPrice(PricingPhaseWrapper phase) {
    try {
      // 反射式取值，沒有此欄位時會丟例外 → 回 null
      final v = (phase as dynamic).formattedPrice as String?;
      return v;
    } catch (_) {
      return null;
    }
  }

  Future<ProductDetails?> _ensureProduct(String productId) async {
    debugPrint('ensureProduct($productId)');
    if (productId.isEmpty) return null;
    final cached = _productMap[productId];
    if (cached != null) {
      debugPrint(' -> hit cache for $productId');
      return cached;
    }
    final map = await IapService.instance.queryProducts({productId});
    debugPrint(' -> queryProducts($productId) => ${map.length}');
    if (map.isNotEmpty) {
      setState(() => _productMap.addAll(map));
      return map[productId];
    }
    return null;
  }


  Future<void> _buySelectedPlan() async {
    final sel = _plans[selectedIndex];
    final t = S.of(context);
    debugPrint('buy plan id=${sel.id} pid=${sel.storeProductId} title=${sel.title}');

// 3)（可選）提示字改成平台專屬，比較不會誤會
    Future<ProductDetails?> _preparePd() async {
      if (!_iapReady) { Fluttertoast.showToast(msg: t.iapUnavailable); return null; }
      final pid = kGetPid(sel);
      if (pid.isEmpty) {
        Fluttertoast.showToast(
          msg: Platform.isAndroid
              ? '此方案未配置 Google Play productId'
              : '此方案未配置 iOS productId',
        );
        return null;
      }
      final pd = await _ensureProduct(pid);
      if (pd == null) { Fluttertoast.showToast(msg: t.iapProductNotFound); }
      return pd;
    }


    if (Platform.isIOS) {
      final pd = await _preparePd();
      if (pd == null) return;

      setState(() => _buying = true);
      try {
        final purchase = await IapService.instance.buyNonConsumable(pd);
        final receipt = purchase.verificationData.serverVerificationData; // iOS 收據(base64)
        await ref.read(walletRepositoryProvider).verifyIapAndCredit(
          platform: 'ios',
          productId: pd.id,
          packetId: sel.id,
          purchaseTokenOrReceipt: receipt,
        );
        await IapService.instance.finish(purchase); // acknowledge/complete
        await _refreshVipAndWallet();
        Fluttertoast.showToast(msg: t.vipOpenSuccess);
      } catch (e) {
        final isCanceled = e
        is IapError &&
            e.message == 'canceled';
        if (isCanceled) {
          Fluttertoast.showToast(
            msg: t.commonCancel,
          );
        }
      } finally {
        if (mounted) setState(() => _buying = false);
      }
      return;
    }
    if (Platform.isAndroid) {
      final pd = await _preparePd();
      if (pd == null) return;

      final gp = pd as GooglePlayProductDetails;
      final offerList = gp.productDetails.subscriptionOfferDetails;
      if (offerList == null || offerList.isEmpty) {
        Fluttertoast.showToast(msg: '此商品沒有可用的 Google Play 方案');
        return;
      }

      final basePlanId = sel.androidBasePlanId; // 後端對應的 base plan
      final offer = offerList.firstWhere(
            (o) => o.basePlanId == basePlanId,
        orElse: () => offerList.first,
      );

      final offerToken = offer.offerIdToken;
      if (offerToken == null || offerToken.isEmpty) {
        Fluttertoast.showToast(msg: '找不到對應的 Google Play base plan（$basePlanId）');
        return;
      }

      setState(() => _buying = true);
      try {
        // ✅ 用 offerToken 進入購買流程，並等 purchaseStream 回傳
        final purchase = await IapService.instance.buySubscription(
          pd,
          offerToken: offerToken,
        );

        // Android 的 token（給後端驗單）
        final token = purchase.verificationData.serverVerificationData;

        // ✅ 後端驗單 + 入帳（跟 iOS 一樣的 API）
        await ref.read(walletRepositoryProvider).verifyIapAndCredit(
          platform: 'android',
          productId: pd.id,   // 這是父商品 id：vip__1m
          packetId: sel.id,   // 你的後台方案 id（方便統計）
          purchaseTokenOrReceipt: token,
        );

        // ✅ 一定要完成交易（acknowledge）
        await IapService.instance.finish(purchase);

        await _refreshVipAndWallet();
        Fluttertoast.showToast(msg: t.vipOpenSuccess);
      } catch (e) {
        final isCanceled = e is IapError && e.message == 'canceled';
        if (isCanceled) {
          Fluttertoast.showToast(
            msg: t.commonCancel,
          );
        }
      } finally {
        if (mounted) setState(() => _buying = false);
      }
      return;
    }

    Fluttertoast.showToast(msg: 'Unsupported platform');
  }

  Future<void> _refreshVipAndWallet() async {
    final walletRepo = ref.read(walletRepositoryProvider);
    final w = await walletRepo.fetchMoneyCash();
    final user = ref.read(userProfileProvider);
    if (user != null) {
      ref.read(userProfileProvider.notifier).state = user.copyWith(
        vipExpire: w.vipExpire, gold: w.gold,
      );
    }
  }

  String _fmtMoney(double v) => '\$ ${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final user = ref.watch(userProfileProvider);
    final vipActive = user?.isVipEffective == true;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(t.vipAppBarTitle, style: const TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 40),

                      // 會員特權卡片（原樣）
                      Container(
                        width: double.infinity,
                        height: 235,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
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
                              Text(t.vipCardTitle,
                                  style: TextStyle(
                                      fontSize: 28, color: Color(0xFF35012B))),
                              const SizedBox(height: 30),
                              Text(t.vipCardSubtitle,
                                  style: TextStyle(
                                      fontSize: 14, color: Color(0xFF35012B))),
                              const Spacer(),
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: Image(
                                      image: user?.avatarImage ?? const AssetImage('assets/my_icon_defult.jpeg'),
                                      width: 30,
                                      height: 30,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // ⬇️ 原本的 Text + Spacer 改成 Expanded（限制暱稱只佔可壓縮區）
                                  Expanded(
                                    child: Text(
                                      user?.displayName ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14, color: Colors.black),
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // ⬇️ 右側用 Flexible + FittedBox，過寬時自動等比縮小到不溢位
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: (user?.isVipEffective ?? false)
                                            ? Text(
                                          _fmtExpire(user?.vipExpireAt),
                                          maxLines: 1,
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                                        )
                                            : Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            t.vipNotActivated,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: Colors.pinkAccent),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 10),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 🟣 方案卡片（可橫向捲動；每個 item 最小間距 10）
                      if (!vipActive) ...[
                        SizedBox(
                          height: 146,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _plans.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final p = _plans[index];
                              final selected = selectedIndex == index;
                              final storePrice = _productMap[kGetPid(p)]?.price; // 例如 US$4.99，會帶幣別與當地含稅

                              return GestureDetector(
                                onTap: () =>
                                    setState(() => selectedIndex = index),
                                child: SizedBox(
                                  width: 115,
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: 6,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 120,
                                          padding: const EdgeInsets.fromLTRB(
                                              12, 6, 12, 6),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? const Color(0xFFFFF5F5)
                                                : Colors.white,
                                            border: Border.all(
                                              color: selected
                                                  ? Colors.red
                                                  : const Color(0xFFE0E0E0),
                                              width: selected ? 2 : 1,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(p.title,
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              const SizedBox(height: 4),
                                            Text(_storePriceForPlan(p) ?? _fmtMoney(p.payPrice),
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.black)),
                                              const SizedBox(height: 4),
                                              Text(t.vipOriginalPrice(_fmtMoney(p.price)),
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                  )),
                                              const SizedBox(height: 4),
                                              Text(t.vipPerMonth(_fmtMoney(p.perMonth)),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (index == _bestIndex)
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          child: Container(
                                            width: 60,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 2),
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFFF4D67),
                                              borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(8),
                                                topLeft: Radius.circular(8),
                                                bottomRight: Radius.circular(8),
                                              ),
                                            ),
                                            child: Text(t.vipBestChoice,
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white)),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // 🟣 專屬特權清單（不變）
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.vipPrivilegesTitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...[
                              {'icon': 'assets/icon_vip_privilege1.svg', 'title': t.privBadgeTitle,       'desc': t.privBadgeDesc},
                              {'icon': 'assets/icon_vip_privilege2.svg', 'title': t.privVisitsTitle,     'desc': t.privVisitsDesc},
                              {'icon': 'assets/icon_vip_privilege3.svg', 'title': t.privUnlimitedCallTitle,'desc': t.privUnlimitedCallDesc},
                              {'icon': 'assets/icon_vip_privilege4.svg', 'title': t.privDirectDmTitle,   'desc': t.privDirectDmDesc},
                              {'icon': 'assets/icon_vip_privilege5.svg', 'title': t.privBeautyTitle,     'desc': t.privBeautyDesc},
                            ].map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFEFEF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: SvgPicture.asset(item['icon']!,
                                          width: 20, height: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black54),
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

                      // 🟣 購買按鈕（用動態方案）
                      if (!vipActive && _plans.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _buying ? null : _buySelectedPlan,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                padding: EdgeInsets.zero,
                                backgroundColor: Colors.transparent,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFFFA06E),
                                    Color(0xFFDC5EF9)
                                  ]),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    t.vipBuyCta(
                                      _fmtMoney(_plans[selectedIndex].payPrice).replaceAll('\$ ', ''), // price (only number)
                                      _plans[selectedIndex].title,                                      // plan title
                                    ), // ← 改
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
    );
  }

  // 放在 _State 裡（工具函式）
  String _fmtExpire(DateTime? dt) {
    if (dt == null) return '';
    final t = S.of(context);
    // 簡單格式化：yyyy-MM-dd HH:mm:ss
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final ss = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm:$ss ${t.vipExpireSuffix}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);          // 👈 解除
    super.dispose();
  }
}
