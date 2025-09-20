import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';

import '../wallet/payment_method_page.dart';
import 'google_purchase_page.dart';             // 新增（下面提供）
import 'ios_purchase_page.dart';                // 你可稍後實作或先用暫代

class PurchaseRouter {
  /// amount: 顯示用（Google/Apple 仍以商城商品價為準）
  /// packetId: 你的禮包 ID（會對應到 productId）
  static Future<void> open(
      BuildContext context, {
        required double amount,
        int? packetId,
        bool isCustom = false,
      }) async {
    // Debug/Profile → 維持你原本的測試頁
    if (!kReleaseMode) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentMethodPage(amount: amount, packetId: packetId),
        ),
      );
      return;
    }

    // Release → 依平台分流
    if (Platform.isAndroid) {
      if (isCustom) {
        // 內購不支援任意自訂金額
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google 內購不支援自訂金額，請選擇固定禮包')),
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GooglePurchasePage(
            packetId: packetId,
            displayAmount: amount,
          ),
        ),
      );
      return;
    }

    if (Platform.isIOS) {
      if (isCustom) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apple 內購不支援自訂金額，請選擇固定禮包')),
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IosPurchasePage(
            packetId: packetId,
            displayAmount: amount,
          ),
        ),
      );
      return;
    }

    // 其他平台 fallback
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodPage(amount: amount, packetId: packetId),
      ),
    );
  }
}