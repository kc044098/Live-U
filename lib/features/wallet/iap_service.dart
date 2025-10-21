import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

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

// IapService.dart
  Future<PurchaseDetails> buySubscription(
      ProductDetails pd, {
        required String offerToken,
      }) async {
    // Android 訂閱一定要用 GooglePlayPurchaseParam + offerToken
    final purchaseParam = GooglePlayPurchaseParam(
      productDetails: pd,
      offerToken: offerToken,
    );

    final completer = Completer<PurchaseDetails>();

    // ❶ 先掛監聽，再啟動購買流程，避免漏接 USER_CANCELED
    final sub = _iap.purchaseStream.listen(
          (events) {
        for (final p in events) {
          if (p.productID != pd.id) continue;

          switch (p.status) {
            case PurchaseStatus.purchased:
            case PurchaseStatus.restored:
              completer.safeComplete(p);
              break;
            case PurchaseStatus.canceled:
              completer.safeCompleteError(IapError('canceled'));
              break;
            case PurchaseStatus.error:
              completer.safeCompleteError(p.error ?? IapError('unknown'));
              break;
            default:
            // pending 等狀態先不處理
              break;
          }
        }
      },
      onError: (e, st) => completer.safeCompleteError(e, st),
    );

    try {
      // ❷ 啟動購買流程
      final started = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        throw IapError('buySubscription start failed');
      }

      // ❸ 等結果（包含 canceled / error）
      return await completer.future.timeout(const Duration(minutes: 2));
    } finally {
      await sub.cancel(); // ❹ 清理監聽，避免重複
    }
  }


  Future<Map<String, ProductDetails>> queryProducts(Set<String> productIds) async {
    if (!_available || productIds.isEmpty) {
      debugPrint('[IAP] skip query: available=$_available ids=$productIds');
      return {};
    }

    debugPrint('[IAP] queryProductDetails ids=$productIds');
    final response = await _iap.queryProductDetails(productIds);
    debugPrint('[IAP][QUERY] found=${response.productDetails.map((e) => e.id).toList()}  notFound=${response.notFoundIDs}');

    if (response.error != null) {
      debugPrint('[IAP] query error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('[IAP] notFoundIDs: ${response.notFoundIDs}');
    }
    debugPrint('[IAP] found: ${response.productDetails.map((e) => e.id).toList()}');

    return { for (final p in response.productDetails) p.id : p };
  }

  Future<PurchaseDetails> buyConsumable(ProductDetails details) async {
    final purchaseParam = PurchaseParam(productDetails: details);
    final completer = Completer<PurchaseDetails>();

    // 先取消舊監聽（避免重複）
    StreamSubscription<List<PurchaseDetails>>? sub;
    sub = _iap.purchaseStream.listen((events) {
      for (final p in events) {
        if (p.productID != details.id) continue;
        debugPrint('[IAP] purchase update id=${p.productID} status=${p.status}');
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
        autoConsume: Platform.isAndroid, // Android 要自動消耗
      );
      if (!ok) throw IapError('buyConsumable start failed');
      final res = await completer.future.timeout(const Duration(minutes: 2));
      return res;
    } finally {
      await sub?.cancel();
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

