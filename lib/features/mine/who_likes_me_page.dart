// 喜歡我的 頁面

import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../wallet/iap_service.dart';
import '../wallet/wallet_repository.dart';
import '../widgets/tools/image_resolver.dart';
import '../../l10n/l10n.dart';
import '../call/call_request_page.dart';
import '../profile/profile_controller.dart';
import '../profile/view_profile_page.dart';
import '../wallet/payment_method_page.dart';
import 'member_fans_provider.dart';
import 'model/fan_user.dart';
import 'model/vip_plan.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:intl/intl.dart';


class WhoLikesMePage extends ConsumerStatefulWidget {
  const WhoLikesMePage({super.key});

  @override
  ConsumerState<WhoLikesMePage> createState() => _WhoLikesMePageState();
}

class _WhoLikesMePageState extends ConsumerState<WhoLikesMePage> {
  final _scroll = ScrollController();

  // VIP 方案區
  List<VipPlan> _plans = const [];
  int _selectedPlanIndex = 1;
  int _bestIndex = 0;
  bool _plansLoading = false;
  String? _plansError;

  // IAP
  bool _iapReady = false;
  bool _buying = false;
  Map<String, ProductDetails> _productMap = {};
  String? _iapWarn;

  late final _PageLifecycleObserver _lifecycleObserver;
  Timer? _buyWatchdog; // 保險定時器，避免極端情況卡住

  // Android 的父訂閱商品（所有 base plan 都在底下）
  static const String kAndroidVipParentProductId = 'vip__1m';

  // 依平台回傳查商店要用的 productId：Android 一律回父商品
  String _pidForQuery(VipPlan p) =>
      Platform.isAndroid ? kAndroidVipParentProductId : p.storeProductId;

  @override
  void initState() {
    super.initState();

    // 進頁面抓第一頁粉絲
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memberFansProvider.notifier).loadFirstPage();
    });

    // 無限滾動載入下一頁
    _scroll.addListener(() {
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      if (pos.pixels >= pos.maxScrollExtent - 300) {
        ref.read(memberFansProvider.notifier).loadNextPage();
      }
    });

    _lifecycleObserver = _PageLifecycleObserver(() {
      if (_buying) {
        debugPrint('[WhoLikesMe] app resumed -> reset _buying & refresh');
        if (mounted) setState(() => _buying = false);  // 讓購買按鈕恢復可按
        _refreshVipAndWallet();                        // 順手刷新，避免漏單
      }
    });
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    _initIap();
  }

  Future<void> _initIap() async {
    try {
      await IapService.instance.init();
      if (!mounted) return;
      setState(() => _iapReady = IapService.instance.isAvailable);
    } catch (_) {
      if (mounted) setState(() => _iapReady = false);
    }
  }

  Future<void> _loadPlansIfNeeded() async {
    final u = ref.read(userProfileProvider);
    final shouldBlock = (u != null) && !(u.isVipEffective || u.isBroadcaster);
    if (!shouldBlock) return;
    if (_plansLoading || _plans.isNotEmpty) return;

    setState(() { _plansLoading = true; _plansError = null; });

    try {
      final repo = ref.read(userRepositoryProvider);
      final plans = await repo.fetchVipPlans();

      // 最佳/預設
      int bestIdx = 0;
      if (plans.isNotEmpty) {
        double bestPer = plans.first.perMonth;
        for (var i = 1; i < plans.length; i++) {
          if (plans[i].perMonth < bestPer) { bestPer = plans[i].perMonth; bestIdx = i; }
        }
      }
      final defaultIdx = (plans.length >= 2) ? 1 : (plans.isNotEmpty ? 0 : 0);

      // 查商店商品（拿價格 + 之後購買要用）
      Map<String, ProductDetails> pMap = {};
      if (_iapReady && plans.isNotEmpty) {
        final Set<String> ids = Platform.isAndroid
            ? { kAndroidVipParentProductId } // ← 只查父商品
            : plans.map((e) => e.storeProductId).where((s) => s.isNotEmpty).toSet();

        if (ids.isNotEmpty) {
          pMap = await IapService.instance.queryProducts(ids);
        } else {
          _iapWarn = 'No productId from backend';
        }
      } else if (!_iapReady) {
        _iapWarn = 'IAP not available';
      }

      if (!mounted) return;
      setState(() {
        _plans = plans;
        _bestIndex = bestIdx;
        _selectedPlanIndex = defaultIdx;
        _plansLoading = false;
        _productMap = pMap;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _plansError = '$e'; _plansLoading = false; });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _buyWatchdog?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final fans = ref.watch(memberFansProvider);
    final me = ref.watch(userProfileProvider);
    final cdn = me?.cdnUrl ?? '';
    final showBlockLayer =
        (me != null) && !(me.isVipEffective || me.isBroadcaster);

    if (showBlockLayer && !_plansLoading && _plans.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_plansLoading && _plans.isEmpty) {
          _loadPlansIfNeeded();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.whoLikesMeTitle,
            style: const TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Stack(
        children: [
          // Grid（任何身份都先渲染；被遮罩蓋住與否，交給 showBlockLayer 控制）
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

          // 只有非 VIP 且非主播才顯示購買 VIP 的遮罩
          if (showBlockLayer) _buildOverlayLayer(t),
        ],
      ),
    );
  }

  Widget _buildLikedCardFromApi(MemberFanUser user, String cdnBase) {
    final coverRaw =
    user.avatars.firstWhere((e) => e.isNotEmpty, orElse: () => '');
    final coverUrl = joinCdnIfNeeded(coverRaw, cdnBase);

    final image = (coverUrl.isNotEmpty && coverUrl.startsWith('http'))
        ? CachedNetworkImage(imageUrl: coverUrl, fit: BoxFit.cover)
        : Image.asset('assets/my_photo_defult.jpeg', fit: BoxFit.cover); // fallback

    return AspectRatio(
      aspectRatio: 3 / 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(child: image),
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
                        user.name.isNotEmpty ? user.name : S.of(context).userFallback,
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
                      onTap: () => _handleCallRequest(context, user, cdnBase),
                      child: SvgPicture.asset(
                        'assets/logo_placeholder.svg',
                        height: 28,
                        width: 28,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCallRequest(BuildContext context, MemberFanUser user, String cdnBase) {
    final broadcasterId = user.id.toString();
    final broadcasterName = user.name;
    final firstAvatar = user.avatars.firstWhere((e) => e.isNotEmpty, orElse: () => '');
    final broadcasterImage = firstAvatar.isNotEmpty
        ? joinCdnIfNeeded(firstAvatar, cdnBase)
        : 'assets/my_icon_defult.jpeg';

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

  Widget _buildOverlayLayer(S t) {
    // 供按鈕文案顯示商店價
    String _selectedDisplayPrice() {
      if (_plans.isEmpty) return _fmtMoney(0);
      final p = _plans[_selectedPlanIndex];
      return _storePriceForPlan(p) ?? _fmtMoney(p.payPrice);
    }

    return Stack(
      children: [
        // iOS/Metal：BackdropFilter 必須包在 ClipRect，並鋪滿畫面
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.6)),
            ),
          ),
        ),
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
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.whoLikesMeTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(
                  t.whoLikesMeSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xfffb5d5d)),
                ),
                const SizedBox(height: 20),

                _plansSection(t),

                const SizedBox(height: 20),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: (_plansLoading || _plans.isEmpty || _buying)
                        ? null
                        : _buySelectedPlan, // ← 改：走 IAP
                    child: Text(
                      _plansLoading || _plans.isEmpty
                          ? t.loadingEllipsis
                          : t.buyVipWithPrice(_selectedDisplayPrice()),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmtMoney(double v) => '\$ ${v.toStringAsFixed(2)}';

  Widget _plansSection(S t) {
    if (_plansLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_plansError != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.planLoadFailed,
              style: const TextStyle(fontSize: 13, color: Colors.white)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _loadPlansIfNeeded, child: Text(t.retry)),
        ],
      );
    }
    if (_plans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(t.noAvailablePlans,
            style: const TextStyle(fontSize: 13, color: Colors.white)),
      );
    }
    return _plansGrid(t);
  }

  Widget _plansGrid(S t) {
    return LayoutBuilder(
      builder: (context, cons) {
        const cols = 3;
        final ts = MediaQuery.textScaleFactorOf(context).clamp(1.0, 1.6);

        // 估算卡片高度，避免文字溢出
        final baseTextH = (14 * 1.25 + 16 * 1.25 + 12 * 1.25 + 12 * 1.25);
        const vPadding = 6.0 * 2;
        const vSpacing = 2.0 * 3;
        final extra = 10.0;
        final tileH = (baseTextH * ts) + vPadding + vSpacing + extra;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _plans.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: tileH + 8,
          ),
          itemBuilder: (context, index) {
            final p = _plans[index];
            final selected = _selectedPlanIndex == index;

            final displayPrice = _storePriceForPlan(p) ?? _fmtMoney(p.payPrice);

            return GestureDetector(
              onTap: () => setState(() => _selectedPlanIndex = index),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? Colors.pink : const Color(0xFFE0E0E0),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: selected
                          ? [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                          : null,
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
                        const SizedBox(height: 2),
                        Text(displayPrice,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(t.vipOriginalPrice(_fmtMoney(p.price)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            )),
                        const SizedBox(height: 2),
                        Text(t.vipPerMonth(_fmtMoney(p.perMonth)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (index == _bestIndex)
                    Positioned(
                      top: -8,
                      left: 0,
                      child: Container(
                        width: 60,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 2, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4D67),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            topLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(t.vipBestChoice,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ====== 商店價（顯示用） ======
  String? _storePriceForPlan(VipPlan p) {
    final String key = Platform.isAndroid ? kAndroidVipParentProductId : p.storeProductId;
    final pd = _productMap[key];
    if (pd == null) return null;

    // iOS：每個 plan 有獨立商品，直接用 pd.price
    if (!Platform.isAndroid) return pd.price;

    // Android：從父商品取出對應 base plan 的 offer
    if (pd is! GooglePlayProductDetails) return pd.price;
    final offers = pd.productDetails.subscriptionOfferDetails;
    if (offers == null || offers.isEmpty) return pd.price;

    final offer = offers.firstWhere(
          (o) => o.basePlanId == p.androidBasePlanId, // 例如 vip3m
      orElse: () => offers.first,
    );

    final List<PricingPhaseWrapper>? phases = offer.pricingPhases;
    if (phases == null || phases.isEmpty) return pd.price;

    final phase = phases.first;

    // 有些 wrapper 帶 formattedPrice
    final fp = tryGetFormattedPrice(phase);
    if (fp != null && fp.isNotEmpty) return fp;

    // fallback：micros + 幣別
    final micros = phase.priceAmountMicros ?? 0;
    final code   = phase.priceCurrencyCode ?? '';
    if (micros <= 0 || code.isEmpty) return pd.price;

    final value = micros / 1000000.0;
    return NumberFormat.simpleCurrency(name: code).format(value);
  }

  String? tryGetFormattedPrice(PricingPhaseWrapper phase) {
    try { return (phase as dynamic).formattedPrice as String?; } catch (_) { return null; }
  }

  Future<void> _buySelectedPlan() async {
    final t = S.of(context);
    if (_plans.isEmpty) return;
    final sel = _plans[_selectedPlanIndex];

    Future<ProductDetails?> _preparePd() async {
      if (!_iapReady) { Fluttertoast.showToast(msg: t.iapUnavailable); return null; }
      final pid = _pidForQuery(sel); // ← 這裡關鍵：Android 會變成 'vip__1m'
      if (pid.isEmpty) {
        Fluttertoast.showToast(
          msg: Platform.isAndroid ? '此方案未配置 Google Play productId'
              : '此方案未配置 iOS productId',
        );
        return null;
      }
      final cached = _productMap[pid];
      if (cached != null) return cached;
      final map = await IapService.instance.queryProducts({pid});
      if (map.isNotEmpty) {
        setState(() => _productMap.addAll(map));
        return map[pid];
      }
      Fluttertoast.showToast(msg: t.iapProductNotFound);
      return null;
    }

    // iOS（不變）...
    if (Platform.isIOS) {
      final pd = await _preparePd();
      if (pd == null) return;
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
        _buyWatchdog?.cancel();
        if (mounted) setState(() => _buying = false);
      }
      return;
    }

    // Android（父商品 + base plan）
    if (Platform.isAndroid) {
      final pd = await _preparePd(); // ← 回來的是 'vip__1m' 的 ProductDetails
      if (pd == null) return;

      final gp = pd as GooglePlayProductDetails;
      final offerList = gp.productDetails.subscriptionOfferDetails;
      if (offerList == null || offerList.isEmpty) {
        Fluttertoast.showToast(msg: '此商品沒有可用的 Google Play 方案');
        return;
      }

      final offer = offerList.firstWhere(
            (o) => o.basePlanId == sel.androidBasePlanId, // 例如 vip12months
        orElse: () => offerList.first,
      );

      final offerToken = offer.offerIdToken;
      if (offerToken == null || offerToken.isEmpty) {
        Fluttertoast.showToast(msg: '找不到對應的 Google Play base plan（${sel.androidBasePlanId}）');
        return;
      }

      setState(() => _buying = true);
      try {
        final purchase = await IapService.instance.buySubscription(pd, offerToken: offerToken);
        final token = purchase.verificationData.serverVerificationData;

        await ref.read(walletRepositoryProvider).verifyIapAndCredit(
          platform: 'android',
          productId: pd.id,   // 這裡會是 'vip__1m'
          packetId: sel.id,   // 你的方案 id
          purchaseTokenOrReceipt: token,
        );

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
        _buyWatchdog?.cancel();
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
      ref.read(userProfileProvider.notifier).state =
          user.copyWith( vipExpire: w.vipExpire, gold: w.gold);
    }
  }
}

class _PageLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onResumed;
  _PageLifecycleObserver(this.onResumed);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) onResumed();
  }
}