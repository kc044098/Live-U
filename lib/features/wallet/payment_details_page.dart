import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
class PaymentDetailsPage extends StatelessWidget {
  final double amount;
  final int coinAmount;
  final String paymentMethod;
  final String time;
  final String orderId;
  final String? payAccount;

  /// 避免以字串（例如「佣金充值」）判斷是否顯示付款帳戶，改用參數控制，語系安全。
  final bool hidePayAccount;

  const PaymentDetailsPage({
    super.key,
    required this.amount,
    required this.coinAmount,
    required this.paymentMethod,
    required this.time,
    required this.orderId,
    this.payAccount,
    this.hidePayAccount = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          t.billDetailTitle, // '账单详情' / 'Bill details'
          style: const TextStyle(fontSize: 16, color: Colors.black),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Image.asset('assets/pic_pay_result.png', width: 120, height: 120),
          const SizedBox(height: 12),

          // 例：'充值—1000金币' / 'Top-up—1000 coins'
          Text(
            '${t.rechargeWord}—$coinAmount${t.coinWord}',
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 8),

          // 金額
          Text(
            amount.toStringAsFixed(2),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // '充值成功' / 'Top-up successful'
          Text(
            t.rechargeSuccess,
            style: const TextStyle(fontSize: 15, color: Colors.redAccent),
          ),
          const SizedBox(height: 32),

          const Divider(
            height: 1, thickness: 1, color: Color(0xFFF0F0F0), indent: 16, endIndent: 16,
          ),
          const SizedBox(height: 8),

          _buildInfoItem(t.rechargeDetails, '\$ ${amount.toStringAsFixed(2)}'),
          // Label 已含單位 → value 僅顯示數字即可
          _buildInfoItem(t.rechargeCoinsLabel, '$coinAmount'),
          _buildInfoItem(t.rechargeMethodLabel, paymentMethod),

          if (!hidePayAccount && payAccount != null)
            _buildInfoItem(t.paymentAccountLabel, payAccount!),

          _buildInfoItem(t.rechargeTimeLabel, time),
          _buildInfoItem(t.rechargeOrderIdLabel, orderId),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}