import 'package:flutter/material.dart';

import 'model/withdraw_record.dart';

class WithdrawInfoPage extends StatelessWidget {
  final WithdrawRecord record;
  const WithdrawInfoPage({super.key, required this.record});

  String _formatDate(int unixSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  String _methodText(String code) {
    switch (code.toLowerCase()) {
      case 'paypal': return 'Paypal';
      case 'visa':   return 'Visa';
      default:       return code.isEmpty ? '未知方式' : code;
    }
  }

  /// 狀態：1=审核中,2=成功,3=审核拒绝,4=审核通过
  (String, Color) _statusTextAndColor(int s) {
    switch (s) {
      case 1: return ('审核中', const Color(0xFFFF4D67)); // 粉色
      case 2: return ('成功',    const Color(0xFF25C685)); // 綠色
      case 3: return ('审核拒绝', const Color(0xFFE53935)); // 紅色
      case 4: return ('审核通过', const Color(0xFFFF4D67)); // 粉色
      default:return ('—', Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor) = _statusTextAndColor(record.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('账单详情', style: TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        children: [
          // 頂部圖 + 金額 + 狀態
          Column(
            children: [
              Image.asset('assets/pic_pay_result.png', width: 160, height: 160),
              const SizedBox(height: 12),
              Text(
                (record.amount.toDouble()).toStringAsFixed(2),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                statusText,
                style: TextStyle(fontSize: 14, color: statusColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(color: Color(0xFFEDEDED)),

          const SizedBox(height: 6),
          _kvRow('提现时间', _formatDate(record.createAt)),
          _kvRow('提现方式', _methodText(record.bankCode)),
          _kvRow('提现账户', record.account.isEmpty ? '—' : record.account),
          _kvRow('提现户名', record.cardName.isEmpty ? '—' : record.cardName),
          _kvRow('提现单号', record.orderNumber.isEmpty ? '—' : record.orderNumber),
        ],
      ),
    );
  }

  Widget _kvRow(String k, String v) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
          ),
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
