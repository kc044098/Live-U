import 'dart:io';

import 'package:djs_live_stream/features/wallet/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../l10n/l10n.dart';
import '../profile/profile_controller.dart';
import 'iap_service.dart';

class PaymentMethodPage extends ConsumerStatefulWidget {
  final double amount; // 顯示於 UI 的金額（美元）
  final int? packetId;
  final String? iosProductId;
  final String? androidProductId;
  final bool isCustom;

  const PaymentMethodPage({
    super.key,
    required this.amount,
    this.packetId,
    this.iosProductId,
    this.androidProductId,
    this.isCustom = false,
  });

  @override
  ConsumerState<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends ConsumerState<PaymentMethodPage> {
  int selectedMethod = 0; // 0=佣金帳戶, 2=App Store, 3=Google Play
  bool isPaying = false;

  int _goldFromAmount(double amount) => (amount * 100).round();

  Future<void> _doRecharge() async {
    final t = S.of(context);
    setState(() => isPaying = true);
    try {
      final repo = ref.read(walletRepositoryProvider);

      // 佣金帳戶
      if (selectedMethod == 0) {
        if (widget.packetId != null) {
          await repo.rechargeGold(id: widget.packetId);
        } else {
          final gold = _goldFromAmount(widget.amount);
          await repo.rechargeGold(gold: gold);
        }
        ref.invalidate(walletBalanceProvider);
        if (!mounted) return;
        Fluttertoast.showToast(msg: t.rechargeSuccess);
        Navigator.pop(context, true);
        return;
      }

      // App Store IAP
      if (Platform.isIOS && selectedMethod == 2) {
        final pid = (widget.iosProductId ?? '').trim();
        if (pid.isEmpty) throw t.iapProductIdMissing;

        final map = await IapService.instance.queryProducts({pid});
        final details = map[pid];
        if (details == null) throw t.iapProductNotFound;

        final purchase = await IapService.instance.buyConsumable(details);

        final receipt = purchase.verificationData.serverVerificationData;
        await repo.verifyIapAndCredit(
          platform: 'ios',
          productId: pid,
          packetId: widget.packetId,
          purchaseTokenOrReceipt: receipt,
        );

        await IapService.instance.finish(purchase);
        ref.invalidate(walletBalanceProvider);
        if (!mounted) return;
        Fluttertoast.showToast(msg: t.rechargeSuccess);
        Navigator.pop(context, true);
        return;
      }

      // Google Play IAP
      if (Platform.isAndroid && selectedMethod == 3) {
        final pid = (widget.androidProductId ?? '').trim();
        if (pid.isEmpty) throw t.iapProductIdMissing;

        final map = await IapService.instance.queryProducts({pid});
        final details = map[pid];
        if (details == null) throw t.iapProductNotFound;

        final purchase = await IapService.instance.buyConsumable(details);

        final token = purchase.verificationData.serverVerificationData;
        await repo.verifyIapAndCredit(
          platform: 'android',
          productId: pid,
          packetId: widget.packetId,
          purchaseTokenOrReceipt: token,
        );

        await IapService.instance.finish(purchase);
        ref.invalidate(walletBalanceProvider);
        if (!mounted) return;
        Fluttertoast.showToast(msg: t.rechargeSuccess);
        Navigator.pop(context, true);
        return;
      }

      throw t.paymentMethodUnsupported;
    } catch (e) {
      Fluttertoast.showToast(msg: S.of(context).rechargeFailed(e));
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
            const SizedBox(width: 8),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final payable = widget.amount > 0 && !isPaying;
    final cashAmount = ref.watch(userProfileProvider)?.cashAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(t.paymentMethodTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(t.payAmountTitle, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            '\$${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            t.approxCoins(_goldFromAmount(widget.amount)),
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
                Text(t.commissionAccount),
                const Spacer(),
                Text(
                  t.availableUsd(_usdFromCents(cashAmount)),
                  style: const TextStyle(color: Colors.pinkAccent, fontSize: 12),
                ),
              ],
            ),
          ),

          // App Store
          if (Platform.isIOS)
            buildRadioTile(
              value: 2,
              content: Row(
                children: [
                  SvgPicture.asset('assets/icon_apple_1.svg', width: 20),
                  const SizedBox(width: 8),
                  Text(t.appStoreBilling),
                ],
              ),
            ),

          // Google Play
          if (Platform.isAndroid)
            buildRadioTile(
              value: 3,
              content: Row(
                children: [
                  SvgPicture.asset('assets/icon_google_1.svg', width: 20),
                  const SizedBox(width: 8),
                  Text(t.googlePlayBilling),
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
                  child: Center(
                    child: Text(
                      t.commonConfirm,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _usdFromCents(int? cents) {
    final v = cents ?? 0;
    final dollars = v ~/ 100;
    final centsPart = v % 100;
    return '$dollars.${centsPart.toString().padLeft(2, '0')}';
  }
}

