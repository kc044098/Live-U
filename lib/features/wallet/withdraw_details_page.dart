import 'package:djs_live_stream/features/wallet/wallet_repository.dart';
import 'package:djs_live_stream/features/wallet/withdraw_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

import '../../l10n/l10n.dart';
import 'model/withdraw_list_controller.dart';
import 'model/withdraw_record.dart';

class WithdrawDetailsPage extends ConsumerStatefulWidget {
  const WithdrawDetailsPage({super.key});

  @override
  ConsumerState<WithdrawDetailsPage> createState() => _WithdrawDetailsPageState();
}

class _WithdrawDetailsPageState extends ConsumerState<WithdrawDetailsPage> {
  final _refreshCtrl = RefreshController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  String _methodText(BuildContext context, WithdrawRecord r) {
    final t = S.of(context);
    switch (r.bankCode.toLowerCase()) {
      case 'paypal':
        return 'PayPal'; // 品牌名保持英文大小寫
      case 'visa':
        return 'Visa';
      default:
        return r.bankCode.isEmpty ? t.unknownMethod : r.bankCode;
    }
  }

  String _formatDate(int unixSec) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unixSec * 1000);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}:${two(dt.second)}';
  }

  String _formatAmount(int amount) => '- ${(amount.toDouble()).toStringAsFixed(2)}';

  Future<void> _onRefresh() async {
    final ctrl = ref.read(withdrawListProvider.notifier);
    await ctrl.loadFirstPage();
    final s = ref.read(withdrawListProvider);
    if (s.error != null) {
      _refreshCtrl.refreshFailed();
    } else {
      _refreshCtrl.refreshCompleted();
      _refreshCtrl.resetNoData();
    }
  }

  Future<void> _onLoading() async {
    final ctrl = ref.read(withdrawListProvider.notifier);
    if (!ref.read(withdrawListProvider).hasMore) {
      _refreshCtrl.loadNoData();
      return;
    }
    await ctrl.loadNextPage();
    final s = ref.read(withdrawListProvider);
    if (s.error != null) {
      _refreshCtrl.loadFailed();
    } else if (!s.hasMore) {
      _refreshCtrl.loadNoData();
    } else {
      _refreshCtrl.loadComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    final state = ref.watch(withdrawListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.withdrawDetailsTitle, style: const TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: Builder(
        builder: (_) {
          if (state.items.isEmpty && state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.items.isEmpty && state.error != null) {
            return Center(child: Text('${t.loadFailedPrefix}${state.error}'));
          }
          if (state.items.isEmpty) {
            return SmartRefresher(
              controller: _refreshCtrl,
              enablePullDown: true,
              enablePullUp: false,
              onRefresh: _onRefresh,
              header: const ClassicHeader(),
              child: Center(child: Text(t.withdrawNoRecords)),
            );
          }

          return SmartRefresher(
            controller: _refreshCtrl,
            enablePullDown: true,
            enablePullUp: true,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            header: const ClassicHeader(),
            footer: CustomFooter(
              builder: (context, mode) {
                Widget body;
                final tt = S.of(context);
                if (mode == LoadStatus.loading) {
                  body = const SizedBox(
                    width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2),
                  );
                } else if (mode == LoadStatus.noMore) {
                  body = Text('— ${tt.noMoreData} —', style: const TextStyle(color: Colors.grey));
                } else if (mode == LoadStatus.failed) {
                  body = Text(tt.loadFailedTapRetry, style: const TextStyle(color: Colors.grey));
                } else {
                  body = const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: body),
                );
              },
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const Divider(
                height: 36, thickness: 1, color: Color(0xFFEDEDED),
              ),
              itemBuilder: (context, index) {
                final r = state.items[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WithdrawInfoPage(record: r),
                      ),
                    );
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.withdrawToMethod(_methodText(context, r)),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(r.createAt),
                              style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                            ),
                          ],
                        ),
                      ),
                      Text(_formatAmount(r.amount), style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
