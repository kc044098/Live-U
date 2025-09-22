import 'package:djs_live_stream/features/wallet/wallet_repository.dart';
import 'package:djs_live_stream/features/wallet/withdraw_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

class WithdrawPage extends ConsumerStatefulWidget {
  const WithdrawPage({super.key});

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends ConsumerState<WithdrawPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  double get _availableAmount {
    final u = ref.watch(currentUserWithWalletProvider);
    final cash = (u?.cashAmount ?? 0);
    return cash.toDouble(); // 後端以分/元請依實際調整
  }

  Future<void> _submit(BuildContext context) async {
    final inputText = _amountController.text.trim();
    final amountDouble = double.tryParse(inputText);
    final account = _accountController.text.trim(); // 提現帳戶 (email/卡號等)
    final name = _nameController.text.trim();       // 提現戶名 (此處當作 card_name 傳)

    // === 前端驗證 ===
    if (account.isEmpty || name.isEmpty) {
      Fluttertoast.showToast(msg: '提現帳戶與提現戶名不可為空');
      return;
    }
    if (amountDouble == null || amountDouble < 1) {
      Fluttertoast.showToast(msg: '提現金額最低為1元');
      return;
    }
    if (amountDouble > _availableAmount) {
      Fluttertoast.showToast(msg: '提現金額大於可提現金額');
      return;
    }

    // 後端參數需要整數 amount（你的範例是 10）
    final amountInt = amountDouble.floor();

    // 目前 UI 先固定「PayPal」，實際可做選單帶不同 bankCode
    const bankCode = 'paypal';

    setState(() => _submitting = true);
    // 簡單 loading（也可改成 showDialog loading）
    try {
      final repo = ref.read(walletRepositoryProvider);

      await repo.withdraw(
        account: account,
        amount: amountInt,
        bankCode: bankCode,
        cardName: name, // 後端欄位 card_name：目前用戶名填入；若後端要卡號請改對應輸入框
      );

      // 刷新錢包餘額，讓「可提現金額」即時更新
      await ref.refresh(walletBalanceProvider.future);

      // 成功提示 + 清空欄位
      if (mounted) _showWithdrawSuccessDialog(context);
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('提現', style: TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WithdrawDetailsPage()),
              );
            },
            child: const Text('明細', style: TextStyle(fontSize: 14, color: Color(0xFFFF4D67))),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('提現金額', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    SvgPicture.asset('assets/icon_money.svg', width: 20, height: 20),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        textAlignVertical: TextAlignVertical.center,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: '請輸入提現金額',
                          hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text.rich(
                    TextSpan(
                      text: '手續費：',
                      style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                      children: [TextSpan(text: '\$1.00', style: TextStyle(color: Colors.black))],
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: '可提現金額：',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                      children: [
                        TextSpan(
                          text: '\$${_availableAmount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFFFF4D67)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Column(
                children: [
                  _buildWithdrawSection(
                    iconPath: 'assets/icon_withdraw1.svg',
                    label: '帳戶類型',
                    value: 'PayPal', // 先固定；之後做選擇表單可改為狀態變數
                    onTap: () {},
                  ),
                  _buildWithdrawSection(
                    iconPath: 'assets/icon_withdraw2.svg',
                    label: '提現帳戶',
                    isInput: true,
                    hintText: '請輸入提現帳戶（如 PayPal Email）',
                    controller: _accountController,
                    onChanged: (text) {}, // 不需要回寫 controller（避免游標跳動）
                  ),
                  _buildWithdrawSection(
                    iconPath: 'assets/icon_withdraw3.svg',
                    label: '提現戶名',
                    isInput: true,
                    hintText: '請輸入提現戶名',
                    controller: _nameController,
                    onChanged: (text) {},
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : () => _submit(context),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 0,
              disabledBackgroundColor: const Color(0xFFE0E0E0),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFA770), Color(0xFFD247FE)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Container(
                alignment: Alignment.center,
                child: _submitting
                    ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(
                  '確定',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWithdrawSection({
    required String label,
    required String iconPath,
    bool isInput = false,
    String? value,
    String? hintText,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset(iconPath, width: 24, height: 24),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(10)),
          child: isInput
              ? TextField(
            controller: controller,
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: hintText ?? '',
              hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 14, color: Colors.black),
            onChanged: onChanged,
          )
              : GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                if (value != null && value.isNotEmpty)
                  Row(
                    children: [
                      SvgPicture.asset('assets/icon_paypal.svg', width: 16, height: 16),
                      const SizedBox(width: 4),
                      Text(value, style: const TextStyle(fontSize: 14, color: Colors.black)),
                    ],
                  ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showWithdrawSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/pic_apply_withdraw.svg', width: 160, height: 160),
                const SizedBox(height: 24),
                const Text(
                  '提現申請已提交',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF4D67)),
                ),
                const SizedBox(height: 12),
                const Text('我們將在三個工作日進行審核，請耐心等待',
                    style: TextStyle(fontSize: 14, color: Color(0xFF666666)), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                SizedBox(
                  width: 300,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      FocusScope.of(context).unfocus();
                      _amountController.clear();
                      _accountController.clear();
                      _nameController.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      elevation: 0,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFA770), Color(0xFFD247FE)]),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Center(
                        child: Text('確定',
                            style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
