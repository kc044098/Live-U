import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../l10n/l10n.dart';
import '../../profile/profile_controller.dart';
import '../../wallet/iap_service.dart';
import '../../wallet/model/coin_packet.dart';
import '../../wallet/payment_method_page.dart';
import '../../wallet/wallet_repository.dart';

Future<void> showInsufficientGoldSheet(
    BuildContext context,
    WidgetRef ref, {
      void Function(int?)? onRechargeTap, // 不足：回傳建議金額(幣)；一般：null
      int? suggestedAmount,               // 不足時帶入(幣)；一般充值= null
    }) {
  // 開啟前先拉一次錢包餘額
  ref.refresh(walletBalanceProvider);
  ref.refresh(coinPacketsProvider);

  return showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _InsufficientGoldSheet(
      onRechargeTap: onRechargeTap,
      suggestedAmount: suggestedAmount,
    ),
  );
}

class _InsufficientGoldSheet extends ConsumerStatefulWidget {
  const _InsufficientGoldSheet({
    this.onRechargeTap,
    this.suggestedAmount,
  });

  final void Function(int?)? onRechargeTap; // 保留原介面（目前不一定會用）
  final int? suggestedAmount;

  @override
  ConsumerState<_InsufficientGoldSheet> createState() => _InsufficientGoldSheetState();
}

class _InsufficientGoldSheetState extends ConsumerState<_InsufficientGoldSheet> {
  int _selectedIndex = 1;

  // === IAP 與商店價 ===
  bool _iapReady = false;
  bool _buying = false;
  String? _iapWarn;
  Map<String, ProductDetails> _storeProducts = {};

  // 自定義金額輸入（需求：先註解保留）
  final TextEditingController _customCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadStoreProducts(List<CoinPacket> packets) async {
    final ids = <String>{};
    for (final p in packets) {
      if (Platform.isIOS && (p.iosProductId ?? '').isNotEmpty) ids.add(p.iosProductId!);
      if (Platform.isAndroid && (p.androidProductId ?? '').isNotEmpty) ids.add(p.androidProductId!);
    }
    if (ids.isEmpty) return;
    final map = await IapService.instance.queryProducts(ids);
    if (!mounted) return;
    setState(() => _storeProducts = map);
  }

  String _fullFmt(BuildContext ctx, int v) {
    final locale = Localizations.maybeLocaleOf(ctx)?.toLanguageTag();
    return NumberFormat.decimalPattern(locale).format(v);
  }

  // 後端價（單位分/角 → 轉美元顯示）
  String _displayPrice(int raw) {
    final double v = raw >= 1000 ? raw / 100.0 : raw.toDouble();
    return v.toStringAsFixed(2);
  }

  // 依平台取商店價字串
  String? _storePriceOf(CoinPacket p) {
    final storeId = Platform.isIOS ? p.iosProductId : p.androidProductId;
    if (storeId == null || storeId.isEmpty) return null;
    return _storeProducts[storeId]?.price; // e.g. US$4.99（含當地幣別/稅）
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final walletAsync = ref.watch(walletBalanceProvider);
    final gold = walletAsync.maybeWhen(data: (t) => t.gold, orElse: () => null);
    final isInsufficient = widget.suggestedAmount != null;
    final double h = (MediaQuery.of(context).size.height * 0.5).clamp(420.0, 560.0);

    final packetsAsync = ref.watch(coinPacketsProvider);

    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          height: h,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            children: [
              // ===== Header =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isInsufficient)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Image.asset('assets/icon_logout_warning.png', width: 48, height: 48),
                    ),
                  if (isInsufficient) const SizedBox(width: 10),
                  Expanded(
                    child: isInsufficient
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.insufficientGoldNow,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          '${s.balancePrefix}${gold == null ? '—' : _fullFmt(context, gold)} ${s.coinsUnit}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Text(s.currentCoins, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(
                          gold == null ? '—' : _fullFmt(context, gold),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF3535),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(s.coinsUnit, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ),
                  IconButton(
                    splashRadius: 20,
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ===== 方案網格 =====
              Expanded(
                child: packetsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text(s.packetsLoadFailed)),
                  data: (packets) {
                    // 第一次拿到資料就查商店價
                    if (_storeProducts.isEmpty) {
                      _loadStoreProducts(packets); // 不 await，避免卡 UI
                    }

                    // ✅ 依需求：先暫時關閉「自定義金額」卡片（保留原碼以備將來啟用）
                    // final customIndex = packets.length;
                    // final itemCount = packets.length + 1;

                    final itemCount = packets.length;

                    if (_selectedIndex >= itemCount) {
                      _selectedIndex = itemCount - 1;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        // final isCustom = index == customIndex;
                        final isSelected = _selectedIndex == index;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedIndex = index),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: SizedBox(
                                  height: 90,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.white : const Color(0xFFF9F9F9),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected ? Colors.red : const Color(0xFFEDEDED),
                                              width: 1.2,
                                            ),
                                          ),
                                          child:
                                          // if (isCustom) ...（保留：自訂卡 UI）
                                          // Center(
                                          //   child: SvgPicture.asset(
                                          //     'assets/icon_edit1.svg',
                                          //     width: 32,
                                          //     colorFilter: ColorFilter.mode(
                                          //       isSelected ? Colors.red : Colors.grey,
                                          //       BlendMode.srcIn,
                                          //     ),
                                          //   ),
                                          // )
                                          Transform.translate(
                                            offset: const Offset(0, 6),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Image.asset('assets/icon_gold1.png', width: 24),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${NumberFormat.decimalPattern(Localizations.maybeLocaleOf(context)?.toLanguageTag())
                                                      .format(packets[index].gold)} ${s.coinsUnit}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isSelected ? Colors.red : const Color(0xFF9E9E9E),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // if (isCustom)
                                      //   Text(s.customAmount, style: const TextStyle(fontSize: 13, color: Colors.black))
                                      // else
                                      Text(
                                        _storePriceOf(packets[index]) ?? '\$${_displayPrice(packets[index].price)}',
                                        style: const TextStyle(fontSize: 12, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (/* !isCustom && */ packets[index].bonus > 0)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFE4CC),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        s.limitedTimeBonus(packets[index].bonus),
                                        style: const TextStyle(fontSize: 10, color: Color(0xFFFF3535)),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ===== 底部：充值按鈕（自訂輸入暫時關閉，保留原碼） =====
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(top: 6),
                child: packetsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => _bottomBar(
                    context: context,
                    // showCustom: false, // 自訂額已關閉
                    onPress: () => Fluttertoast.showToast(msg: s.packetsNotReady),
                  ),
                  data: (packets) {
                    // final customIndex = packets.length;
                    // final isCustomSelected = _selectedIndex == customIndex;

                    return _bottomBar(
                      context: context,
                      // showCustom: isCustomSelected, // ← 關閉自訂欄
                      // controller: _customCtrl,
                      onPress: () => _onRechargePressed(context, packets),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar({
    required BuildContext context,
    required VoidCallback onPress,
    TextEditingController? controller,
    bool showCustom = false,
  }) {
    final s = S.of(context);
    return Row(
      children: [
        // 自訂輸入（暫時關閉，保留）
        // if (showCustom)
        //   Expanded(
        //     child: Container(
        //       height: 46,
        //       padding: const EdgeInsets.symmetric(horizontal: 12),
        //       decoration: BoxDecoration(
        //         color: const Color(0xFFF7F7F7),
        //         borderRadius: BorderRadius.circular(20),
        //       ),
        //       child: TextField(
        //         controller: controller,
        //         keyboardType: TextInputType.number,
        //         inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        //         decoration: InputDecoration(
        //           border: InputBorder.none,
        //           hintText: s.enterRechargeAmount,
        //           hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        //         ),
        //       ),
        //     ),
        //   ),
        // if (showCustom) const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: _buying ? null : onPress,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
              ),
              child: Ink(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                child: Center(
                  child: _buying
                      ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : Text(
                    s.recharge,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onRechargePressed(BuildContext context, List<CoinPacket> packets) async {
    final t = S.of(context);

    if (packets.isEmpty) {
      Fluttertoast.showToast(msg: t.walletPacketsNotLoaded);
      return;
    }
    if (_selectedIndex < 0 || _selectedIndex >= packets.length) {
      Fluttertoast.showToast(msg: t.walletChoosePacketFirst);
      return;
    }

    final picked = packets[_selectedIndex];

    // ===== iOS：IAP 消耗型購買 =====
    if (Platform.isIOS) {
      if (!_iapReady) { Fluttertoast.showToast(msg: t.iapUnavailable); return; }
      final productId = picked.iosProductId ?? '';
      if (productId.isEmpty) { Fluttertoast.showToast(msg: t.iapProductIdMissing); return; }

      // 取商品資訊（先看快取，沒有就補查）
      ProductDetails? pd = _storeProducts[productId];
      if (pd == null) {
        final map = await IapService.instance.queryProducts({productId});
        pd = map[productId];
      }
      if (pd == null) { Fluttertoast.showToast(msg: t.iapProductNotFound); return; }

      setState(() => _buying = true);
      try {
        final purchase = await IapService.instance.buyConsumable(pd);
        final receipt = purchase.verificationData.serverVerificationData;

        await ref.read(walletRepositoryProvider).verifyIapAndCredit(
          platform: 'ios',
          productId: pd.id,
          packetId: picked.id,
          purchaseTokenOrReceipt: receipt,
        );

        await IapService.instance.finish(purchase);

        await _refreshWallet();
        Fluttertoast.showToast(msg: t.rechargeSuccess);

        // 可選：通知外部
        widget.onRechargeTap?.call(picked.id);

        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        Fluttertoast.showToast(msg: t.rechargeFailedShort);
      } finally {
        if (mounted) setState(() => _buying = false);
      }
      return;
    }

    // ===== Android：Google Play Billing 消耗型購買 =====
    if (Platform.isAndroid) {
      if (!_iapReady) { Fluttertoast.showToast(msg: t.iapUnavailable); return; }
      final productId = picked.androidProductId ?? '';
      if (productId.isEmpty) { Fluttertoast.showToast(msg: t.iapProductIdMissing); return; }

      ProductDetails? pd = _storeProducts[productId];
      if (pd == null) {
        final map = await IapService.instance.queryProducts({productId});
        pd = map[productId];
      }
      if (pd == null) {
        final pkg = (await PackageInfo.fromPlatform()).packageName;
        debugPrint('[IAP][ANDROID] productId "$productId" not found from Play, pkg=$pkg');
        Fluttertoast.showToast(msg: '此商品尚未在 Google Play 生效（或非測試帳號 / 非同一套件軌道）');
        return;
      }

      setState(() => _buying = true);
      try {
        final purchase = await IapService.instance.buyConsumable(pd);
        final token = purchase.verificationData.serverVerificationData;

        await ref.read(walletRepositoryProvider).verifyIapAndCredit(
          platform: 'android',
          productId: pd.id,
          packetId: picked.id,
          purchaseTokenOrReceipt: token,
        );

        await IapService.instance.finish(purchase);

        await _refreshWallet();
        Fluttertoast.showToast(msg: t.rechargeSuccess);

        widget.onRechargeTap?.call(picked.id);

        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        Fluttertoast.showToast(msg: t.rechargeFailedShort);
      } finally {
        if (mounted) setState(() => _buying = false);
      }
      return;
    }

    Fluttertoast.showToast(msg: 'Unsupported platform');
  }

  Future<void> _refreshWallet() async {
    final walletRepo = ref.read(walletRepositoryProvider);
    final w = await walletRepo.fetchMoneyCash();
    // 如果你有用 walletBalanceProvider 做 UI，也可以：ref.refresh(walletBalanceProvider);
    final user = ref.read(userProfileProvider);
    if (user != null) {
      ref.read(userProfileProvider.notifier).state =
          user.copyWith(gold: w.gold, vipExpire: w.vipExpire);
    }
  }
}
