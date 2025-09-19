import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../wallet/payment_method_page.dart';
import '../../wallet/wallet_repository.dart';

Future<void> showInsufficientGoldSheet(
    BuildContext context,
    WidgetRef ref, {
      void Function(int?)? onRechargeTap, // 不足：回傳建議金額(幣)；一般：null
      int? suggestedAmount,               // 不足時帶入(幣)；一般充值= null
    }) {
  // 開啟前先拉一次錢包餘額
  ref.refresh(walletBalanceProvider);
  ref.refresh(coinPacketsProvider);

  return showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _InsufficientGoldSheet(
      onRechargeTap: onRechargeTap,
      suggestedAmount: suggestedAmount,
    ),
  );
}
class _InsufficientGoldSheet extends ConsumerStatefulWidget {
  const _InsufficientGoldSheet({
    this.onRechargeTap,
    this.suggestedAmount,
  });

  final void Function(int?)? onRechargeTap;
  final int? suggestedAmount;

  @override
  ConsumerState<_InsufficientGoldSheet> createState() => _InsufficientGoldSheetState();
}

class _InsufficientGoldSheetState extends ConsumerState<_InsufficientGoldSheet> {
  int _selectedIndex = 1;

  // 自定義金額輸入（顯示在「充值」左邊）
  final TextEditingController _customCtrl = TextEditingController();

  String _fullFmt(BuildContext ctx, int v) {
    final locale = Localizations.maybeLocaleOf(ctx)?.toLanguageTag();
    return NumberFormat.decimalPattern(locale).format(v); // ← 完整數字
  }

  String _displayPrice(int raw) {
    final double v = raw >= 1000 ? raw / 100.0 : raw.toDouble();
    return v.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletBalanceProvider);
    final gold = walletAsync.maybeWhen(data: (t) => t.gold, orElse: () => null);
    final isInsufficient = widget.suggestedAmount != null;
    final double h = (MediaQuery.of(context).size.height * 0.5).clamp(420.0, 560.0);

    final packetsAsync = ref.watch(coinPacketsProvider);

    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          height: h,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            children: [
              // ===== Header =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isInsufficient)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Image.asset('assets/icon_logout_warning.png', width: 48, height: 48),
                    ),
                  if (isInsufficient) const SizedBox(width: 10),
                  Expanded(
                    child: isInsufficient
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('當前金幣不足！',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          '餘額：${gold == null ? '—' : _fullFmt(context, gold)} 金幣',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        const Text('當前金幣：',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text(
                          gold == null ? '—' : _fullFmt(context, gold),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF3535),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('個', style: TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ),
                  IconButton(
                    splashRadius: 20,
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ===== 方案網格 =====
              Expanded(
                child: packetsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('禮包載入失敗')),
                  data: (packets) {
                    final customIndex = packets.length;           // ★ 最末為自定義
                    final itemCount = packets.length + 1;
                    final isCustomSelected = _selectedIndex == customIndex;

                    // 避免 index 溢位
                    if (_selectedIndex >= itemCount) {
                      _selectedIndex = itemCount - 1;
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.9,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        final isCustom = index == customIndex;
                        final isSelected = _selectedIndex == index;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedIndex = index),
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: SizedBox(
                                  height: 90,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.white : const Color(0xFFF9F9F9),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected ? Colors.red : const Color(0xFFEDEDED),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: isCustom
                                              ? Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              SvgPicture.asset(
                                                'assets/icon_edit1.svg',
                                                width: 32,
                                                colorFilter: ColorFilter.mode(
                                                  isSelected ? Colors.red : Colors.grey,
                                                  BlendMode.srcIn,
                                                ),
                                              ),
                                            ],
                                          )
                                              : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Image.asset('assets/icon_gold1.png', width: 28),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${NumberFormat.decimalPattern().format(packets[index].gold)}币',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: isSelected ? Colors.red : const Color(0xFF9E9E9E),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      isCustom
                                          ? const Text('自定义金额', style: TextStyle(fontSize: 13, color: Colors.black))
                                          : Text(
                                        '\$${_displayPrice(packets[index].price)}',
                                        style: const TextStyle(fontSize: 12, color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isCustom && packets[index].bonus > 0)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFE4CC),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '限時贈送${packets[index].bonus}幣',
                                        style: const TextStyle(fontSize: 10, color: Color(0xFFFF3535)),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ===== 底部：自定義輸入 + 充值 =====
              SafeArea(
                top: false,
                minimum: const EdgeInsets.only(top: 6),
                child: packetsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => _bottomBar(
                    context: context,
                    showCustom: false,
                    onPress: () => Fluttertoast.showToast(msg: '禮包尚未載入，請稍候'),
                  ),
                  data: (packets) {
                    final customIndex = packets.length;
                    final isCustomSelected = _selectedIndex == customIndex;

                    return _bottomBar(
                      context: context,
                      showCustom: isCustomSelected,
                      controller: _customCtrl,
                      onPress: () {
                        // 先關閉面板
                        Navigator.pop(context);

                        // 若外部有 callback，交還（維持原簽名與行為）
                        if (widget.onRechargeTap != null) {
                          widget.onRechargeTap!(widget.suggestedAmount);
                          return;
                        }

                        if (isCustomSelected) {
                          // ★ 自訂金額：只帶 amount
                          final parsed = double.tryParse(_customCtrl.text.trim());
                          if (parsed == null || parsed < 1) {
                            Fluttertoast.showToast(msg: '至少輸入 1 元');
                            return;
                          }
                          if (parsed % 1 != 0) {
                            Fluttertoast.showToast(msg: '金額必須是整數');
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentMethodPage(amount: parsed),
                            ),
                          );
                        } else {
                          // ★ 後端禮包：帶 packetId + amount
                          if (_selectedIndex < 0 || _selectedIndex >= packets.length) {
                            Fluttertoast.showToast(msg: '請先選擇禮包');
                            return;
                          }
                          final picked = packets[_selectedIndex];
                          final amountToPay = (picked.price >= 1000)
                              ? picked.price / 100.0
                              : picked.price.toDouble();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentMethodPage(
                                amount: amountToPay,
                                packetId: picked.id, // ✅ 帶上 packetId
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomBar({
    required BuildContext context,
    required VoidCallback onPress,
    TextEditingController? controller,
    bool showCustom = false,
  }) {
    return Row(
      children: [
        if (showCustom)
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '请输入您的充值金额',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ),
          ),
        if (showCustom) const SizedBox(width: 12),
        SizedBox(
          height: 46,
          width: showCustom ? 140 : MediaQuery.of(context).size.width - 32,
          child: ElevatedButton(
            onPressed: onPress,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
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
                child: Text(
                  '充值',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
