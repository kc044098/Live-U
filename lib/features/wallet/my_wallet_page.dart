import 'dart:io';
import 'dart:typed_data';
import 'package:djs_live_stream/features/wallet/payment_method_page.dart';
import 'package:djs_live_stream/features/wallet/wallet_detail_page.dart';
import 'package:djs_live_stream/features/wallet/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../data/models/user_model.dart';
import '../profile/profile_controller.dart';
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
        Fluttertoast.showToast(msg: '讀取錢包失敗');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 以 moneyCash 結果優先，其次用 user.gold，最後 fallback 0
    final int coinAmount = _gold ?? (user.gold ?? 0);

    final packetsAsync = ref.watch(coinPacketsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,          // 關掉 scrolled-under 陰影
        surfaceTintColor: Colors.transparent,
        title: const Text('我的錢包', style: TextStyle(color: Colors.black, fontSize: 16)),
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
            child: const Text('明細', style: TextStyle(color: Colors.red, fontSize: 16)),
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
                    const Text('禮包載入失敗', style: TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    Text('$e', style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => ref.refresh(coinPacketsProvider),
                      child: const Text('重試'),
                    ),
                  ],
                ),
              ),
              data: (packets) => Column(
                children: [
                  _buildRechargeGrid(packets),
                  if (selectedIndex == packets.length) _buildCustomAmountInput(), // ★ custom 卡 index = packets.length
                ],
              ),
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
              child: const Center(
                child: Text(
                  '立即充值',
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
              Text(user.displayName?? '未知', style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$coinAmount', style: const TextStyle(color: Colors.white, fontSize: 30)),
                const Text('金幣餘額', style: TextStyle(color: Colors.white, fontSize: 14)),
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
                                    '自定义金额',
                                    style: TextStyle(
                                      fontSize: 14,
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
                  ),
                ],
              ),
            );
          }

          // 一般禮包卡
          final p = packets[index];
          final displayPrice = _displayPrice(p.price);
          final bonusText = p.bonus > 0 ? '限時贈送${p.bonus}幣' : null;

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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/icon_gold1.png', width: 36),
                                const SizedBox(height: 6),
                                Text(
                                  '${formatNumber(p.gold)}币',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected ? Colors.red : Colors.black,
                                  ),
                                ),
                              ],
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE4CC),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        bonusText,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('自定义充值', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '请输入您的充值金额',
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
    final double v = raw >= 1000 ? raw / 100.0 : raw.toDouble();
    return v.toStringAsFixed(2);
  }

  void _onRechargePressed() {
    final packetsAsync = ref.read(coinPacketsProvider);
    final packets = packetsAsync.asData?.value ?? [];

    if (packets.isEmpty) {
      Fluttertoast.showToast(msg: '禮包尚未載入，請稍候');
      return;
    }

    final customIndex = packets.length;
    final isCustom = selectedIndex == customIndex;

    if (isCustom) {
      // 自訂金額 → 只帶 amount
      final input = _customAmountController.text.trim();
      final parsed = double.tryParse(input);

      if (parsed == null || parsed < 1) {
        Fluttertoast.showToast(msg: '至少輸入1元');
        return;
      }
      if (parsed % 1 != 0) {
        Fluttertoast.showToast(msg: '金額必須是整數');
        return;
      }

      FocusScope.of(context).unfocus();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentMethodPage(
            amount: parsed,
            // packetId: null  // 可不寫，預設就是 null
          ),
        ),
      );
      return;
    }

    // 選擇前面禮包 → 帶入 packetId + amount
    if (selectedIndex < 0 || selectedIndex >= packets.length) {
      Fluttertoast.showToast(msg: '請先選擇禮包');
      return;
    }
    final picked = packets[selectedIndex];

    // 若後端 price 為「分」，你可用規則轉成實際金額（這裡沿用之前示例）
    final amountToPay = (picked.price >= 1000)
        ? picked.price / 100.0
        : picked.price.toDouble();

    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodPage(
          amount: amountToPay,
          packetId: picked.id, // ★ 帶禮包 id
        ),
      ),
    );
  }
}
