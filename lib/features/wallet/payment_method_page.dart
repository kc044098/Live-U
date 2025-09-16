import 'package:djs_live_stream/features/wallet/payment_details_page.dart';
import 'package:djs_live_stream/features/wallet/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PaymentMethodPage extends ConsumerStatefulWidget {
  final double amount; // 顯示於 UI 的金額（美元）
  final int? packetId;

  const PaymentMethodPage({
    super.key,
    required this.amount,
    this.packetId,
  });

  @override
  ConsumerState<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends ConsumerState<PaymentMethodPage> {
  int selectedMethod = 0;
  bool isPaying = false;

  int _goldFromAmount(double amount) => (amount * 100).round();

  // 支付方式對照表
  final paymentMethods = [
    '佣金充值',
    '信用卡',
    'PayPal充值',
    'Google Pay',
  ];

  // 可選帳號（僅部分有）
  final payAccounts = [
    null,                   // 佣金充值不需要帳號
    null,                   // 新卡也不需要
    '1234567890@163.com',   // PayPal 帳戶（DEMO）
    'user@gmail.com',       // Google Pay 帳戶（DEMO）
  ];

  Future<void> _doRecharge() async {
    setState(() => isPaying = true);
    try {
      final repo = ref.read(walletRepositoryProvider);

      if (widget.packetId != null) {
        // ★ 禮包：只傳 id
        await repo.rechargeGold(id: widget.packetId);
      } else {
        // ★ 自訂金額：只傳 gold
        final gold = _goldFromAmount(widget.amount);
        await repo.rechargeGold(gold: gold);
      }

      // 成功後刷新餘額
      ref.invalidate(walletBalanceProvider);

      if (!mounted) return;
      final toast = (widget.packetId != null)
          ? '禮包充值成功'
          : '充值成功：+${_goldFromAmount(widget.amount)} 金幣';
      Fluttertoast.showToast(msg: toast);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(msg: '充值失敗：$e');
    } finally {
      if (mounted) setState(() => isPaying = false);
    }
  }

  Widget buildRadioTile({
    required int value,
    required Widget content,
  }) {
    return InkWell(
      onTap: () => setState(() => selectedMethod = value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              selectedMethod == value
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: Colors.pinkAccent,
            ),
            const SizedBox(width: 12),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final payable = widget.amount > 0 && !isPaying;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('支付方式'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const Text('支付金額', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            '\$${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          // 顯示換算後金幣（測試）
          Text(
            '≈ ${_goldFromAmount(widget.amount)} 金幣',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // 佣金帳戶
          buildRadioTile(
            value: 0,
            content: Row(
              children: [
                SvgPicture.asset('assets/icon_money_1.svg', width: 20),
                const SizedBox(width: 8),
                const Text('佣金帳戶'),
                const Spacer(),
                const Text('可用 100美元', style: TextStyle(color: Colors.pinkAccent)),
              ],
            ),
          ),

          // Add a new card
          buildRadioTile(
            value: 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SvgPicture.asset('assets/icon_card_1.svg', width: 20),
                    const SizedBox(width: 8),
                    const Text('Add a new card'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Image.asset('assets/pic_card_1.png', width: 36),
                    const SizedBox(width: 6),
                    Image.asset('assets/pic_card_2.png', width: 36),
                    const SizedBox(width: 6),
                    Image.asset('assets/pic_card_3.png', width: 36),
                  ],
                ),
              ],
            ),
          ),

          // PayPal
          buildRadioTile(
            value: 2,
            content: Row(
              children: [
                SvgPicture.asset('assets/icon_apple_1.svg', width: 20),
                const SizedBox(width: 8),
                const Text('PayPal'),
              ],
            ),
          ),

          // Google Pay
          buildRadioTile(
            value: 3,
            content: Row(
              children: [
                SvgPicture.asset('assets/icon_google_1.svg', width: 20),
                const SizedBox(width: 8),
                const Text('Google Pay'),
              ],
            ),
          ),

          const Spacer(),

          // 支付按鈕 + loading
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: isPaying
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ),
                onPressed: payable ? _doRecharge : null,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                    ),
                  ),
                  child: const Center(
                    child: Text('確定', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}