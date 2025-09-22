import 'package:djs_live_stream/features/message/gift/show_insufficient_gold_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/gift_item.dart';
import '../../live/gift_providers.dart';
import '../../profile/profile_controller.dart';
import '../../wallet/wallet_repository.dart';

import 'package:intl/intl.dart';

// Bottom Sheet（TikTok 風）
class GiftBottomSheet extends ConsumerStatefulWidget {
  const GiftBottomSheet({
    super.key,
    required this.onSelected,                 // 只發聊天訊息（後端解析扣款）
    this.onRechargeTap,                      // 金幣不足時 → 儲值頁（可帶建議金額）
    this.height = 420,
    this.crossAxisCount = 4,
    this.itemSpacing = 12,
  });

  /// 回傳 true=訊息送出成功（僅傳聊天訊息，不打送禮 API）
  final Future<bool> Function(GiftItemModel gift) onSelected;

  /// 若金幣不足，會呼叫 onRechargeTap(shortfall)。
  /// 若使用者直接點右下「儲值」，會呼叫 onRechargeTap(null)。
  final void Function(int? amount)? onRechargeTap;

  final double height;
  final int crossAxisCount;
  final double itemSpacing;

  @override
  ConsumerState<GiftBottomSheet> createState() => _GiftBottomSheetState();
}

class _GiftBottomSheetState extends ConsumerState<GiftBottomSheet> {
  bool _locking = false;
  int? _sendingIndex;

  @override
  void initState() {
    super.initState();
    // 開啟面板時載入禮物 & 拉一次錢包
    Future.microtask(() =>
        ref.read(giftListProvider.notifier).loadIfStale(const Duration(minutes: 10)));
    Future.microtask(() => ref.refresh(walletBalanceProvider));
  }

  String _fullUrl(String base, String p) {
    if (p.isEmpty) return p;
    if (p.startsWith('http')) return p;
    if (base.isEmpty) return p;
    return p.startsWith('/') ? '$base$p' : '$base/$p';
  }

  Future<int?> _getGoldEnsured() async {
    final wa = ref.read(walletBalanceProvider);
    final cached = wa.maybeWhen(
      data: (w) => w.gold,   // ★ 改成讀 record 的 gold
      orElse: () => null,
    );
    if (cached != null) return cached;

    try {
      final w = await ref.refresh(walletBalanceProvider.future);
      return w.gold;         // ★ 這裡也改
    } catch (_) {
      return null;
    }
  }

  int _suggestTopUpAmount(int shortfall) {
    // 你可以改為靠後端儲值檔或方案階梯；這裡先直接用短缺額
    // 例如：向上取整到 60 / 300 / 680 / 1280 ... 也可在這裡做。
    return shortfall <= 0 ? 0 : shortfall;
  }

  @override
  Widget build(BuildContext context) {
    final giftsAsync = ref.watch(normalGiftListProvider);
    final cdnBase = ref.watch(userProfileProvider)?.cdnUrl ?? '';
    final walletAsync = ref.watch(walletBalanceProvider);
    final gold = walletAsync.maybeWhen(
      data: (w) => w.gold,
      orElse: () => null,
    );

    const double kBottomBarH = 56;

    return SafeArea(
      top: false,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Container(
          height: widget.height,
          color: const Color(0xFF0F0F10), // 黑底
          child: Stack(
            children: [
              // 內容
              Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: giftsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: Colors.white70),
                      ),
                      error: (e, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('載入禮物失敗：$e',
                                style: const TextStyle(color: Colors.redAccent)),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: const BorderSide(color: Colors.white24),
                              ),
                              onPressed: () => ref.read(giftListProvider.notifier).refresh(),
                              child: const Text('重試'),
                            ),
                          ],
                        ),
                      ),
                      data: (gifts) {
                        if (gifts.isEmpty) {
                          return const Center(
                            child: Text('暫無禮物', style: TextStyle(color: Colors.white70)),
                          );
                        }
                        return Scrollbar(
                          thumbVisibility: true,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16 + kBottomBarH),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: widget.crossAxisCount,
                              crossAxisSpacing: widget.itemSpacing,
                              mainAxisSpacing: widget.itemSpacing,
                              childAspectRatio: .78,
                            ),
                            itemCount: gifts.length,
                            itemBuilder: (_, i) {
                              final g = gifts[i];
                              final icon = _fullUrl(cdnBase, g.icon);

                              return Opacity(
                                opacity: _locking && _sendingIndex != i ? 0.6 : 1,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _locking ? null : () async {
                                    setState(() { _locking = true; _sendingIndex = i; });

                                    // 1) 取得當前金幣
                                    final currentGold = await _getGoldEnsured();

                                    if (currentGold == null) {
                                      await showInsufficientGoldSheet(
                                        context,
                                        ref,
                                        onRechargeTap: widget.onRechargeTap,
                                      );
                                      if (mounted) setState(() { _locking = false; _sendingIndex = null; });
                                      return;
                                    }

                                    // 2) 判斷是否足夠
                                    if (currentGold < g.gold) {
                                      final shortfall = g.gold - currentGold;
                                      final suggest = _suggestTopUpAmount(shortfall);
                                      // 彈出不足金幣的儲值彈窗（或呼叫外部導頁）
                                      await showInsufficientGoldSheet(
                                        context,
                                        ref,
                                        onRechargeTap: widget.onRechargeTap,
                                        suggestedAmount: suggest,
                                      );
                                      if (mounted) setState(() { _locking = false; _sendingIndex = null; });
                                      return;
                                    }

                                    // 3) 足夠 → 只送出聊天訊息（後端解析扣款）
                                    final ok = await widget.onSelected(g);

                                    if (!mounted) return;

                                    if (ok) {
                                      // 4) 刷新錢包
                                      ref.refresh(walletBalanceProvider);

                                      // 5) 關閉 GiftBottomSheet ✅
                                      Navigator.of(context).pop(true);
                                      return; // 記得 return，避免往下 reset 狀態
                                    }

                                    // 送出失敗 → 保持面板開著
                                    setState(() { _locking = false; _sendingIndex = null; });
                                  },
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1C1C20),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Stack(
                                        children: [
                                          Column(
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(10),
                                                  child: icon.isNotEmpty
                                                      ? Image.network(icon, fit: BoxFit.cover)
                                                      : const SizedBox.shrink(),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                g.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontSize: 12, color: Colors.white),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.monetization_on,
                                                      size: 14, color: Colors.amber),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${g.gold}',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          if (_sendingIndex == i)
                                            const Positioned.fill(
                                              child: Center(
                                                child: SizedBox(
                                                  width: 20, height: 20,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // 底部工具列（右下餘額 / 儲值）
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Container(
                    height: kBottomBarH,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F0F10),
                      border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const SizedBox.shrink(),
                        const Spacer(),
                        _RechargeButton(
                          gold: gold,
                          onTap: () async {
                            await showInsufficientGoldSheet(
                              context,
                              ref,
                              onRechargeTap: widget.onRechargeTap, // 交給外層處理真正前往儲值
                              suggestedAmount: null,               // 這裡不帶建議金額；需要也可以帶
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RechargeButton extends StatelessWidget {
  const _RechargeButton({this.onTap, this.gold});
  final VoidCallback? onTap;
  final int? gold;

  String _compact(BuildContext context, int v) {
    final locale = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    return NumberFormat.compact(locale: locale).format(v);
  }

  @override
  Widget build(BuildContext context) {
    final hasGold = (gold ?? 0) > 0;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F23),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white12, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Image.asset('assets/icon_gold1.png', width: 18, height: 18),
            ),
            const SizedBox(width: 6),
            Text(
              hasGold ? _compact(context, gold!) : '儲值',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (!hasGold)
              const Padding(
                padding: EdgeInsets.only(top: 2, left: 2),
                child: Icon(Icons.chevron_right, size: 22, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}