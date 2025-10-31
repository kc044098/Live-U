import 'package:djs_live_stream/features/wallet/recharge_detail_page.dart';
import 'package:djs_live_stream/features/wallet/wallet_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import '../../l10n/l10n.dart';
import '../profile/profile_controller.dart';
import 'model/finance_record.dart';

enum LedgerType { all, recharge, sendGift, receiveGift, videoPaid, voicePaid, campaign }

// 目前只有充值先啟用，其它先留空集合（等你提供 flag 對照）
final Map<LedgerType, Set<int>> _typeToFlags = const {
  LedgerType.all: {},
  LedgerType.recharge: {1},
  LedgerType.sendGift: {101},
  LedgerType.receiveGift: {100},
  LedgerType.videoPaid: {104},
  LedgerType.voicePaid: {105},
  LedgerType.campaign: {5},
};

class WalletDetailPage extends ConsumerStatefulWidget {
  const WalletDetailPage({super.key});

  @override
  ConsumerState<WalletDetailPage> createState() => _WalletDetailPageState();
}

class _WalletDetailPageState extends ConsumerState<WalletDetailPage> {
  final RefreshController _refreshController =
  RefreshController(initialRefresh: true);

  final List<FinanceRecord> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = false;

  // 目前僅支援顯示的旗標（沒定義就不顯示）
  static const Set<int> _supportedFlags = {1, 101, 100, 104, 105, 5};

  // 當前選擇的交易類型（預設「全部」）
  LedgerType _typeFilter = LedgerType.all;

  Future<void> _fetchPage({required bool refresh}) async {
    if (_loading) return;
    _loading = true;
    try {
      final repo = ref.read(walletRepositoryProvider);
      final nextPage = refresh ? 1 : (_page + 1);
      final pageItems = await repo.fetchFinanceList(page: nextPage);

      if (refresh) {
        _items
          ..clear()
          ..addAll(pageItems);
        _page = 1;
      } else {
        _items.addAll(pageItems);
        _page = nextPage;
      }

      // 這裡只算一次
      _hasMore = pageItems.isNotEmpty;

      // ✅ 僅保留一套完成邏輯：refresh 不進 noMore；load 時才決定 complete/noMore
      if (refresh) {
        _refreshController.refreshCompleted();
        _refreshController.resetNoData(); // 首頁即便空也不要顯示 no more
      } else {
        if (_hasMore) {
          _refreshController.loadComplete();
        } else {
          _refreshController.loadNoData();
        }
      }

      setState(() {});
    } catch (e) {
      if (refresh) {
        _refreshController.refreshFailed();
      } else {
        _refreshController.loadFailed();
      }
    } finally {
      _loading = false;
    }
  }


  Future<void> _onRefresh() => _fetchPage(refresh: true);
  Future<void> _onLoading() {
    if (!_hasMore) {
      _refreshController.loadNoData();
      return Future.value();
    }
    return _fetchPage(refresh: false);
  }

  String _formatTime(int tsSeconds) {
    if (tsSeconds <= 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(tsSeconds * 1000);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
  }

  String _titleFor(S t, FinanceRecord r) {
    switch (r.flag) {
      case 1:   return '${t.rechargeWord} - ${t.coinWord}';
      case 101: {
        final name = r.nickName.trim();
        return name.isNotEmpty ? t.giftToName(name) : t.giftSent;
      }
      case 100: return t.titleReceiveGift;
      case 104: return t.filterVideoPaid;
      case 105: return t.filterVoicePaid;
      case 5:   return t.filterCampaign;
      default:  return '';
    }
  }

  // 回傳 (文字, 顏色)。依你的設計，正負皆用黑色。
  (String text, Color color) _amountFor(FinanceRecord r) {
    switch (r.flag) {
      case 1:   // 充值 → +
      case 100: // 收禮 → +
      case 5:   // 活動獎勵 → +
        return ('+${r.gold}', Colors.black);
      case 101: // 送禮 → -
      case 104: // 視頻消費 → -
      case 105: // 語音消費 → -
        return ('-${r.gold}', Colors.black);
      default:
        return ('', Colors.black);
    }
  }

  // 新增這個小工具，之後用它取代 CircleAvatar(backgroundImage: ...)
  Widget _avatarDot(String? rawUrl) {
    final url = _resolveAvatarUrl(rawUrl);
    if (url == null) {
      return const CircleAvatar(radius: 10, child: Icon(Icons.person, size: 12));
    }
    return ClipOval(
      child: Image.network(
        url,
        width: 20,
        height: 20,
        fit: BoxFit.cover,
        // 網址壞掉也不要拋例外
        errorBuilder: (_, __, ___) =>
        const CircleAvatar(radius: 10, child: Icon(Icons.person, size: 12)),
      ),
    );
  }



  String? _resolveAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;

    final cdn = ref.read(userProfileProvider)?.cdnUrl ?? '';
    if (cdn.isEmpty) return null;

    return url.startsWith('/') ? '$cdn$url' : '$cdn/$url';
  }


  bool _needsPartnerInfo(FinanceRecord r) =>
      const {101, 100, 104, 105}.contains(r.flag);

  List<FinanceRecord> get _visibleItems {
    // 先只保留「我們已定義好要顯示的 flag」
    Iterable<FinanceRecord> base = _items.where((e) => _supportedFlags.contains(e.flag));

    // 類型=全部 → 不再過濾；否則依類型對照過濾
    if (_typeFilter == LedgerType.all) return base.toList();

    final flags = _typeToFlags[_typeFilter] ?? const <int>{};
    if (flags.isEmpty) return const []; // 類型尚未定義 → 顯示空
    return base.where((e) => flags.contains(e.flag)).toList();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final list = _visibleItems;
    final canPullUp = list.isNotEmpty && _hasMore;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.walletDetails, style: const TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => _showFilterBottomSheet(context),
            child: Text(t.filter, style: const TextStyle(color: Colors.pinkAccent, fontSize: 16)),
          ),
        ],
      ),
      body: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: canPullUp,
        onRefresh: _onRefresh,
        onLoading: _onLoading,
        header: const WaterDropHeader(),
        footer: CustomFooter(
          builder: (ctx, mode) {
            final tt = S.of(ctx);
            if (!canPullUp) return const SizedBox(height: 10);
            switch (mode) {
              case LoadStatus.loading:
                return const SizedBox(height: 44, child: Center(child: CupertinoActivityIndicator()));
              case LoadStatus.failed:
                return SizedBox(height: 44, child: Center(child: Text(tt.loadFailedTapRetry)));
              case LoadStatus.noMore:
                return const SizedBox(height: 10);
              default:
                return const SizedBox(height: 10);
            }
          },
        ),
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 8),
          itemCount: list.isEmpty ? 1 : (list.length + 1),
          itemBuilder: (context, index) {
            if (list.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(top: 80, bottom: 200),
                child: _EmptyView(),
              );
            }
            if (index == list.length) {
              return const SizedBox(height: 10);
            }

            final item = list[index];
            final title = _titleFor(t, item);

            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(title, style: const TextStyle(fontSize: 16)),
                  subtitle: Text(
                    _formatTime(item.createAt),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  trailing: SizedBox(width: 140, child: _trailingBlock(item)),
                  onTap: (item.flag == 1)
                      ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RechargeDetailPage(oId: item.oId),
                      ),
                    );
                  }
                      : null,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    final t = S.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        LedgerType temp = _typeFilter;

        // 與設計稿一致的順序
        final options = <(LedgerType type, String label)>[
          (LedgerType.all,        t.filterAll),
          (LedgerType.recharge,   t.filterRecharge),
          (LedgerType.sendGift,   t.filterSendGift),
          (LedgerType.receiveGift,t.filterReceiveGift),
          (LedgerType.videoPaid,  t.filterVideoPaid),
          (LedgerType.voicePaid,  t.filterVoicePaid),
          (LedgerType.campaign,   t.filterCampaign),
        ];

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0x22000000),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(t.selectTransactionType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 24),

                    // ✅ 動態均分 + 間距 20
                    LayoutBuilder(
                      builder: (ctx, constraints) {
                        const double spacing = 20;
                        const double minItemWidth = 96; // 視覺基準（不會被硬塞）
                        final double w = constraints.maxWidth;

                        // 動態推算欄數（至少 2 欄）
                        int crossAxisCount =
                        ((w + spacing) / (minItemWidth + spacing)).floor();
                        if (crossAxisCount < 2) crossAxisCount = 2;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: options.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            mainAxisExtent: 64,
                          ),
                          itemBuilder: (_, i) {
                            final (type, label) = options[i];
                            final selected = temp == type;

                            return GestureDetector(
                              onTap: () {
                                // 1) 更新底部單內的選中狀態（紅框）
                                setModalState(() => temp = type);
                                // 2) 立即套用到列表（不關閉底部單）
                                setState(() => _typeFilter = type);

                                _refreshController.resetNoData();
                              },
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFFFFF0F0) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected ? Colors.pink : const Color(0xFFE0E0E0),
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selected ? Colors.pink : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// （B）_trailingBlock：將 Row 固定寬，文字用 Expanded 吃剩餘空間
  Widget _trailingBlock(FinanceRecord r) {
    final (amountText, amountColor) = _amountFor(r);
    final showPartner = _needsPartnerInfo(r);
    final name = (r.nickName.isNotEmpty ? r.nickName : '—');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(amountText, style: TextStyle(fontSize: 18, color: amountColor)),
        if (showPartner) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: 120, // 🔒 鎖寬，避免 Row 超界
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _avatarDot(r.avatar),     // ← 用新工具
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 80),
        child: Text(t.walletNoRecords),
      ),
    );
  }
}