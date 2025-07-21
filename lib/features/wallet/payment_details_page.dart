import 'package:flutter/material.dart';

class PaymentDetailsPage extends StatelessWidget {
  final double amount;
  final int coinAmount;
  final String paymentMethod;
  final String time;
  final String orderId;
  final String? payAccount;

  const PaymentDetailsPage({
    super.key,
    required this.amount,
    required this.coinAmount,
    required this.paymentMethod,
    required this.time,
    required this.orderId,
    this.payAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('账单详情',
            style: TextStyle(fontSize: 16, color: Colors.black)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 32),
          Image.asset('assets/pic_pay_result.png', width: 120, height: 120),
          const SizedBox(height: 12),
          const Text('充值—XXX币', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            amount.toStringAsFixed(2),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('充值成功',
              style: TextStyle(fontSize: 15, color: Colors.redAccent)),
          const SizedBox(height: 32),

          const Divider(
              height: 1, thickness: 1, color: Color(0xFFF0F0F0), indent: 16, endIndent: 16),
          const SizedBox(height: 8),

          _buildInfoItem('充值详情', '\$ ${amount.toStringAsFixed(2)}'),
          _buildInfoItem('充值XXX币', '$coinAmount 个'),
          _buildInfoItem('充值方式', paymentMethod),
          if (paymentMethod != '佣金充值' && payAccount != null)
            _buildInfoItem('付款账户', payAccount!),
          _buildInfoItem('充值时间', time),
          _buildInfoItem('充值单号', orderId),
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
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 14, color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
