import 'dart:io';

import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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

class _VipPrivilegePageState extends ConsumerState<VipPrivilegePage> {
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

  @override
  void initState() {
    super.initState();
    _initIap().then((_) => _loadPlans());
  }

  Future<void> _initIap() async {
    try {
      await IapService.instance.init();
      setState(() => _iapReady = IapService.instance.isAvailable);
    } catch (_) {
      setState(() => _iapReady = false);
    }
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(userRepositoryProvider);
      final plans = await repo.fetchVipPlans();
      final t = S.of(context);

      if (!mounted) return;

      if (plans.isEmpty) {
        setState(() {
          _plans = const [];
          selectedIndex = 0;
          _bestIndex = 0;
          _loading = false;
        });
        return;
      }

      // 預設選擇：優先 3 個月，其次「每月單價最低」
      int defaultIdx = plans.indexWhere((p) => p.month == 3);
      if (defaultIdx < 0) {
        double best = double.infinity;
        for (var i = 0; i < plans.length; i++) {
          final pm = plans[i].perMonth;
          if (pm < best) {
            best = pm;
            defaultIdx = i;
          }
        }
        if (defaultIdx < 0) defaultIdx = 0;
      }

      // 「最佳選擇」：每月單價最低
      int bestIdx = 0;
      double bestPer = plans.first.perMonth;
      for (var i = 1; i < plans.length; i++) {
        if (plans[i].perMonth < bestPer) {
          bestPer = plans[i].perMonth;
          bestIdx = i;
        }
      }

      // 如果是 iOS 且 IAP 可用 → 查商品
      Map<String, ProductDetails> pMap = {};
      String? iapWarn;
      if (Platform.isIOS && _iapReady) {
        final ids = plans.map((e) => e.productId).where((s) => s.isNotEmpty).toSet();
        if (ids.isNotEmpty) {
          pMap = await IapService.instance.queryProducts(ids);
          if (pMap.isEmpty) iapWarn = t.iapWarnNoProducts;         // ← 改
        } else {
          iapWarn = t.iapWarnNoProductId;                           // ← 改
        }
      }

      setState(() {
        _plans = plans;
        selectedIndex = defaultIdx;
        _bestIndex = bestIdx;
        _loading = false;
        _productMap = pMap;
        _iapWarn = iapWarn;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<ProductDetails?> _ensureProduct(String productId) async {
    if (productId.isEmpty) return null;
    final cached = _productMap[productId];
    if (cached != null) return cached;
    // 補查單一商品
    final map = await IapService.instance.queryProducts({productId});
    if (map.isNotEmpty) {
      setState(() => _productMap.addAll(map));
      return map[productId];
    }
    return null;
  }

  Future<void> _buySelectedPlan() async {
    final sel = _plans[selectedIndex];
    final t = S.of(context);
    if (Platform.isIOS) {
      if (!_iapReady) { Fluttertoast.showToast(msg: t.iapUnavailable); return; }
      if (sel.productId.isEmpty) { Fluttertoast.showToast(msg: t.iapProductIdMissing); return; }
      final pd = await _ensureProduct(sel.productId);
      if (pd == null) { Fluttertoast.showToast(msg: t.iapProductNotFound); return; }

      setState(() => _buying = true);
      try {
        final purchase = await IapService.instance.buyNonConsumable(pd);
        final receipt = purchase.verificationData.serverVerificationData;

        await ref.read(walletRepositoryProvider).verifyIapAndCredit(
          platform: 'ios',
          productId: pd.id,
          packetId: sel.id,
          purchaseTokenOrReceipt: receipt,
        );
        await IapService.instance.finish(purchase);

        final walletRepo = ref.read(walletRepositoryProvider);
        final w = await walletRepo.fetchMoneyCash();
        final user = ref.read(userProfileProvider);
        if (user != null) {
          ref.read(userProfileProvider.notifier).state = user.copyWith(
            isVip: true, vipExpire: w.vipExpire, gold: w.gold,
          );
        }
        Fluttertoast.showToast(msg: t.vipOpenSuccess); // ← 改
      } catch (e) {
        Fluttertoast.showToast(msg: t.vipOpenFailed('$e')); // ← 改
      } finally {
        if (mounted) setState(() => _buying = false);
      }
      return;
    }

    // Android 日後再接
    Fluttertoast.showToast(msg: 'Android 訂閱即將開放');
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
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t.loadFailed(_error!)),
                      const SizedBox(height: 12),
                      OutlinedButton(
                          onPressed: _loadPlans, child: Text(t.retry)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 70),

                      // 顯示 IAP 警語（若有）
                      if (_iapWarn != null && _iapWarn!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3F3),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFFFD6D6)),
                            ),
                            child: Text(_iapWarn!,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.red)),
                          ),
                        ),

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
                                      image: user?.avatarImage ??
                                          const AssetImage(
                                              'assets/my_icon_defult.jpeg'),
                                      width: 30,
                                      height: 30,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(user?.displayName ?? '',
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black)),
                                  const Spacer(),
                                  (user?.isVipEffective ?? false)
                                      ? Text(
                                          _fmtExpire(user?.vipExpireAt),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF9E9E9E)),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                    child: Text(t.vipNotActivated,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.pinkAccent)),
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
                                              Text(_fmtMoney(p.payPrice),
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
                                                horizontal: 8, vertical: 2),
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
}
