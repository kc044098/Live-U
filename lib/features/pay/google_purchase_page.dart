
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class GooglePurchasePage extends StatefulWidget {
  final int? packetId;        // 你的禮包 ID（會轉成 productId）
  final double displayAmount; // 顯示用

  const GooglePurchasePage({
    super.key,
    required this.packetId,
    required this.displayAmount,
  });

  @override
  State<GooglePurchasePage> createState() => _GooglePurchasePageState();
}

class _GooglePurchasePageState extends State<GooglePurchasePage> {
  final InAppPurchase _iap = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _sub;

  bool _available = false;
  bool _loading = true;
  String? _error;
  ProductDetails? _product;

  String _mapPacketIdToProductId(int packetId) {
    // 🔧 跟 Play Console 的商品 ID 對應（請用相同規則命名）
    // 例如在 Play 建立 coin_pack_1, coin_pack_2 ...
    return 'coin_pack_$packetId';
  }

  @override
  void initState() {
    super.initState();
    _initStore();
    _sub = _iap.purchaseStream.listen(_onPurchaseUpdated, onError: (_) {});
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<void> _initStore() async {
    try {
      final ok = await _iap.isAvailable();
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _available = false;
          _loading = false;
          _error = 'Google Play 服務不可用';
        });
        return;
      }

      if (widget.packetId == null) {
        setState(() {
          _available = true;
          _loading = false;
          _error = '缺少商品 ID（packetId）';
        });
        return;
      }

      final productId = _mapPacketIdToProductId(widget.packetId!);
      final resp = await _iap.queryProductDetails({productId});
      if (!mounted) return;

      if (resp.error != null) {
        setState(() {
          _available = true;
          _loading = false;
          _error = '查詢商品失敗：${resp.error!.message}';
        });
        return;
      }
      if (resp.productDetails.isEmpty) {
        setState(() {
          _available = true;
          _loading = false;
          _error = '找不到商品 $productId，請確認 Play Console 已建立並可測試';
        });
        return;
      }

      setState(() {
        _available = true;
        _product = resp.productDetails.first;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _available = false;
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _buy() async {
    final p = _product;
    if (p == null) return;
    final param = PurchaseParam(productDetails: p);

    // ✅ 自動消耗 consumable（Google 會在購買成功後自動可再次購買）
    await _iap.buyConsumable(
      purchaseParam: param,
      autoConsume: true,
    );
  }


  Future<void> _onPurchaseUpdated(List<PurchaseDetails> list) async {
    for (final purchase in list) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
        // TODO: 把 purchase.verificationData.serverVerificationData 傳給你的後端驗證
        // ✅ 不需要手動 consume，因為上面已 autoConsume: true

          if (purchase.pendingCompletePurchase) {
            try {
              await _iap.completePurchase(purchase);
            } catch (_) {}
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('購買成功')),
            );
            Navigator.pop(context, true);
          }
          break;

        case PurchaseStatus.pending:
          break;

        case PurchaseStatus.canceled:
          break;

        case PurchaseStatus.error:
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('購買失敗，請稍後再試')),
            );
          }
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _product;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google 內購'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_available
          ? Center(child: Text(_error ?? 'Google Play 不可用'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (p != null) ...[
              ListTile(
                title: Text(p.title, maxLines: 2),
                subtitle: Text(p.description, maxLines: 3),
                trailing: Text(p.price),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _buy,
                  child: Text('購買（${p.price}）'),
                ),
              ),
            ] else
              const Text('找不到對應商品'),
          ],
        ),
      ),
    );
  }
}