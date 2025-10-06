import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class IapService {
  IapService._();
  static final IapService instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;

  bool _available = false;
  bool get isAvailable => _available;

  /// 啟動 IAP（App 啟動時、或進充值頁前呼叫一次）
  Future<void> init() async {
    _available = await _iap.isAvailable();
  }


  Future<Map<String, ProductDetails>> queryProducts(Set<String> productIds) async {
    if (!_available || productIds.isEmpty) return {};
    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      debugPrint('[IAP] query error: ${response.error}');
    }
    return { for (final p in response.productDetails) p.id : p };
  }

  /// 訂閱/非消耗性（內購解鎖、訂閱都走這條）
  Future<PurchaseDetails> buyNonConsumable(ProductDetails details) async {
    final purchaseParam = PurchaseParam(productDetails: details);
    final completer = Completer<PurchaseDetails>();

    final sub = _iap.purchaseStream.listen((events) {
      for (final p in events) {
        if (p.productID != details.id) continue;
        switch (p.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            completer.safeComplete(p);
            break;
          case PurchaseStatus.error:
            completer.safeCompleteError(p.error ?? IapError('unknown'));
            break;
          case PurchaseStatus.canceled:
            completer.safeCompleteError(IapError('canceled'));
            break;
          default:
            break;
        }
      }
    }, onError: (e, st) => completer.safeCompleteError(e, st));

    try {
      final ok = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!ok) throw IapError('buyNonConsumable start failed');
      final res = await completer.future.timeout(const Duration(minutes: 2));
      return res;
    } finally {
      await sub.cancel();
    }
  }

  /// 購買（消耗型）
  Future<PurchaseDetails> buyConsumable(ProductDetails details) async {
    final purchaseParam = PurchaseParam(productDetails: details);
    final completer = Completer<PurchaseDetails>();

    final sub = _iap.purchaseStream.listen((events) {
      for (final p in events) {
        if (p.productID != details.id) continue;

        switch (p.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            completer.safeComplete(p);
            break;
          case PurchaseStatus.error:
            completer.safeCompleteError(p.error ?? IapError('unknown'));
            break;
          case PurchaseStatus.canceled:
            completer.safeCompleteError(IapError('canceled'));
            break;
          default:
            break;
        }
      }
    }, onError: (e, st) => completer.safeCompleteError(e, st));

    try {
      final ok = await _iap.buyConsumable(
        purchaseParam: purchaseParam,
        autoConsume: Platform.isAndroid,
      );
      if (!ok) {
        throw IapError('buyConsumable start failed');
      }
      final res = await completer.future.timeout(const Duration(minutes: 2));
      return res;
    } finally {
      await sub.cancel();
    }
  }

  /// 完成交易（重要）
  Future<void> finish(PurchaseDetails details) async {
    if (details.pendingCompletePurchase) {
      await _iap.completePurchase(details);
    }
  }
}

class IapError implements Exception {
  final String message;
  IapError(this.message);
  @override
  String toString() => 'IapError: $message';
}
extension CompleterSafe<T> on Completer<T> {
  void safeComplete(T value) {
    if (!isCompleted) complete(value);
  }

  void safeCompleteError(Object error, [StackTrace? st]) {
    if (!isCompleted) completeError(error, st);
  }
}