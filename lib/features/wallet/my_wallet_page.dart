import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:djs_live_stream/features/wallet/wallet_detail_page.dart';
import 'package:djs_live_stream/features/wallet/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../data/models/user_model.dart';
import '../../l10n/l10n.dart';
import '../pay/purchase_router.dart';
import '../profile/profile_controller.dart';
import 'iap_service.dart';
import 'model/coin_packet.dart';

class MyWalletPage extends ConsumerStatefulWidget {
  const MyWalletPage({super.key});

  @override
  ConsumerState<MyWalletPage> createState() => _MyWalletPageState();
}

class _MyWalletPageState extends ConsumerState<MyWalletPage> {
  int selectedIndex = 0;
  int? _gold;        // ← 從 moneyCash 取得後暫存於此
  final TextEditingController _customAmountController = TextEditingController();
  Map<String, ProductDetails> _storeProducts = {};

  @override
  void initState() {
    super.initState();
    // 首次進入頁面時載入餘額（最小頻率，不做即時刷新）
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final repo = ref.read(walletRepositoryProvider);
        final w = await repo.fetchMoneyCash();

        if (!mounted) return;
        setState(() {
          _gold = w.gold;
        });

        final user = ref.read(userProfileProvider);
        if (user != null) {
          ref.read(userProfileProvider.notifier).state =
              user.copyWith(gold: w.gold, vipExpire: w.vipExpire);
        }
      } catch (e) {
        // 靜默失敗即可，避免打擾 UI；需要時可加上 toast
        Fluttertoast.showToast(msg: S.of(context).walletReadFail);
      }
    });

    IapService.instance.init();
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final t = S.of(context);

    // 以 moneyCash 結果優先，其次用 user.gold，最後 fallback 0
    final int coinAmount = _gold ?? (user.gold ?? 0);

    final packetsAsync = ref.watch(coinPacketsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,          // 關掉 scrolled-under 陰影
        surfaceTintColor: Colors.transparent,
        title: Text(t.walletTitle, style: const TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletDetailPage()),
              );
            },
            child: Text(t.walletDetails, style: const TextStyle(color: Colors.red, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(user, coinAmount),

            // ★ 用後端資料建 Grid
            packetsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(t.walletPacketsLoadFail, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    Text('$e', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => ref.refresh(coinPacketsProvider),
                      child: Text(t.retry),
                    ),
                  ],
                ),
              ),
              data: (packets) {
                // 第一次載到資料時去拉取商店商品
                if (_storeProducts.isEmpty) {
                  // 不 await，避免卡 UI
                  _loadStoreProducts(packets);
                }
                return Column(
                  children: [
                    _buildRechargeGrid(packets),
                    if (selectedIndex == packets.length) _buildCustomAmountInput(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onRechargePressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: EdgeInsets.zero,
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
                child: Text(
                  t.walletBtnTopupNow,
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user, int coinAmount) {
    final t = S.of(context);
    return Container(
      height: 180,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/bg_my_wallet.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: user.avatarImage,
              ),
              const SizedBox(width: 12),
              Text(user.displayName ?? t.unknown, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$coinAmount', style: const TextStyle(color: Colors.white, fontSize: 30)),
                Text(t.walletBalanceLabel, style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeGrid(List<CoinPacket> packets) {
    final customIndex = packets.length; // ★ 最後一個是自訂金額
    final itemCount = packets.length + 1;
    final t = S.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final isCustom = index == customIndex;

          // 目前是否被選中
          final isSelected = selectedIndex == index;

          // 自訂金額卡
          if (isCustom) {
            return GestureDetector(
              onTap: () => setState(() => selectedIndex = index),
              child: Stack(
                children: [
                  SizedBox(
                    height: 140,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFEFEF) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.red : const Color(0xFFEDEDED),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/icon_edit1.svg',
                                  width: 36,
                                  colorFilter: ColorFilter.mode(
                                    isSelected ? Colors.red : Colors.grey,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  t.walletCustomAmount,
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isSelected ? Colors.red : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const SizedBox(height: 18), // 無價格欄
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          // 一般禮包卡
          final p = packets[index];
          final storeId = Platform.isIOS ? p.iosProductId : p.androidProductId;
          final storePrice = (storeId != null) ? _storeProducts[storeId]?.price : null;
          final displayPrice = storePrice ?? _displayPrice(p.price); // 優先顯示商店價格
          final bonusText = p.bonus > 0 ? t.walletBonusGift(p.bonus) : null;

          return GestureDetector(
            onTap: () => setState(() => selectedIndex = index),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    height: 125,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFEFEF) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.red : const Color(0xFFEDEDED),
                                width: 1.5,
                              ),
                            ),
                            child:
                            Transform.translate(
                              offset: const Offset(0, 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/icon_gold1.png', width: 36),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${formatNumber(p.gold)} ${t.coin}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isSelected ? Colors.red : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${displayPrice}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                if (bonusText != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0, // ★ 有了 right 就有寬度約束，Text 才會換行
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE4CC),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        bonusText!,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 2,                // ★ 需要可再調整
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Color(0xFFFF3535)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomAmountInput() {
    final t = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.walletCustomTopup, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: t.walletCustomHintAmount,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  String _displayPrice(int raw) {
    final double v = raw / 100.0;
    return v.toStringAsFixed(2);
  }

  void _onRechargePressed() {
    final t = S.of(context);
    final packets = ref.read(coinPacketsProvider).asData?.value ?? [];
    if (packets.isEmpty) {
      Fluttertoast.showToast(msg: t.walletPacketsNotLoaded);
      return;
    }

    final customIndex = packets.length;
    final isCustom = selectedIndex == customIndex;

    if (isCustom) {
      final input = _customAmountController.text.trim();
      final parsed = double.tryParse(input);
      if (parsed == null || parsed < 1 || parsed % 1 != 0) {
        Fluttertoast.showToast(msg: t.walletEnterIntAmountAtLeast1);
        return;
      }
      FocusScope.of(context).unfocus();
      PurchaseRouter.open(
        context,
        amount: parsed,
        packetId: null,
        iosProductId: null,                 // 自訂金額沒有對應 IAP
        androidProductId: null,
        isCustom: true,
      );
      return;
    }

    if (selectedIndex < 0 || selectedIndex >= packets.length) {
      Fluttertoast.showToast(msg: t.walletChoosePacketFirst);
      return;
    }

    final picked = packets[selectedIndex];
    final amountToPay = (picked.price >= 1000)
        ? picked.price / 100.0
        : picked.price.toDouble();

    FocusScope.of(context).unfocus();

    PurchaseRouter.open(
      context,
      amount: amountToPay,
      packetId: picked.id,
      iosProductId: picked.iosProductId,           // ★ 新增
      androidProductId: picked.androidProductId,   // ★ 新增
      isCustom: false,
    );
  }

}
