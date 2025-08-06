import 'dart:io';

import 'package:djs_live_stream/features/wallet/payment_method_page.dart';
import 'package:djs_live_stream/features/wallet/wallet_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../data/models/user_model.dart';
import '../profile/profile_controller.dart';

class MyWalletPage extends ConsumerStatefulWidget {
  const MyWalletPage({super.key});

  @override
  ConsumerState<MyWalletPage> createState() => _MyWalletPageState();
}

class _MyWalletPageState extends ConsumerState<MyWalletPage> {
  int selectedIndex = 0;
  final TextEditingController _customAmountController = TextEditingController();

  final List<Map<String, dynamic>> rechargeOptions = [
    {'coins': 1000, 'price': 10},
    {'coins': 3000, 'price': 30, 'bonus': '限時贈送250幣'},
    {'coins': 5000, 'price': 50},
    {'coins': 11000, 'price': 100, 'bonus': '限時贈送1000幣'},
    {'coins': 60000, 'price': 500},
    {'custom': true},
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // final String nickname = user.displayName ?? '未知';
    final int coinAmount = 1000; // TODO: 後續從 user 資料取得

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的錢包', style: TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WalletDetailPage()),
              );
            },
            child: const Text('明細', style: TextStyle(color: Colors.red, fontSize: 16)),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // 預留底部按鈕空間
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(user, coinAmount),
            _buildRechargeGrid(),
            if (selectedIndex == rechargeOptions.length - 1) _buildCustomAmountInput(),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onRechargePressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: EdgeInsets.zero,
            ),
            child: Ink(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              child: const Center(
                child: Text('立即充值',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel user, int coinAmount) {
    return Container(
      height: 180,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/bg_my_wallet.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: user.avatarImage,
              ),
              const SizedBox(width: 12),
              Text(user.displayName?? '未知', style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$coinAmount', style: const TextStyle(color: Colors.white, fontSize: 30)),
                const Text('金幣餘額', style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rechargeOptions.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final item = rechargeOptions[index];
          final isSelected = selectedIndex == index;

          return GestureDetector(
            onTap: () => setState(() => selectedIndex = index),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SizedBox(
                    height: 125,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFEFEF) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? Colors.red : const Color(0xFFEDEDED),
                                width: 1.5,
                              ),
                            ),
                            child: item['custom'] == true
                                ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset('assets/icon_edit1.svg', width: 36),
                                const SizedBox(height: 6),
                                const Text('自定义金额', style: TextStyle(fontSize: 14)),
                              ],
                            )
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/icon_gold1.png', width: 36),
                                const SizedBox(height: 6),
                                Text(
                                  '${item['coins']}币',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isSelected ? Colors.red : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        item['custom'] != true
                            ? Text('\$${item['price'].toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, color: Colors.black54))
                            : const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                if (item['bonus'] != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE4CC),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        item['bonus'],
                        style: const TextStyle(fontSize: 10, color: Color(0xFFFF3535)),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomAmountInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('自定义充值', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _customAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '请输入您的充值金额（1–1000美元）',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onRechargePressed() {
    final isCustom = selectedIndex == rechargeOptions.length - 1;

    if (isCustom) {
      final input = _customAmountController.text.trim();
      final parsed = double.tryParse(input);

      if (parsed == null || parsed < 1) {
        Fluttertoast.showToast(msg: '至少輸入1元');
        return;
      }

      if (parsed % 1 != 0) {
        Fluttertoast.showToast(msg: '金額必須是整數');
        return;
      }

      setState(() {
        selectedIndex = 0;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentMethodPage(amount: parsed),
        ),
      );

      return;
    }

    final amountToPay = (rechargeOptions[selectedIndex]['price'] as num).toDouble();

    FocusScope.of(context).unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentMethodPage(amount: amountToPay),
      ),
    );
  }
}
