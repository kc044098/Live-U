
import 'package:flutter/material.dart';

import '../wallet/payment_method_page.dart';

class PurchaseRouter {
  static Future<void> open(
      BuildContext context, {
        required double amount,
        int? packetId,
        String? iosProductId,        // ★ 新增
        String? androidProductId,    // ★ 新增
        bool isCustom = false,
      }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodPage(
          amount: amount,
          packetId: packetId,
          iosProductId: iosProductId,        // ★ 傳遞
          androidProductId: androidProductId, // ★ 傳遞
          isCustom: isCustom,
        ),
      ),
    );
  }
}


