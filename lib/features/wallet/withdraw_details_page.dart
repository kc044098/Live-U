import 'package:djs_live_stream/features/wallet/wallet_repository.dart';
import 'package:djs_live_stream/features/wallet/withdraw_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

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
    // 首次進頁時就載入（若你 provider 已在建立時 loadFirstPage，也可省略）
    // ref.read(withdrawListProvider.notifier).loadFirstPage();
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  String _methodText(WithdrawRecord r) {
    switch (r.bankCode.toLowerCase()) {
      case 'paypal':
        return 'Paypal';
      case 'visa':
        return 'Visa';
      default:
        return r.bankCode.isEmpty ? '未知方式' : r.bankCode;
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
      // 重整後允許再次上拉
      _refreshCtrl.resetNoData();
    }
  }

  Future<void> _onLoading() async {
    final ctrl = ref.read(withdrawListProvider.notifier);
    // 若沒有更多就直接結束
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
    final state = ref.watch(withdrawListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('提現明細', style: TextStyle(fontSize: 16, color: Colors.black)),
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
          // 初次載入中
          if (state.items.isEmpty && state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          // 初次失敗
          if (state.items.isEmpty && state.error != null) {
            return Center(child: Text('載入失敗：${state.error}'));
          }
          // 無資料
          if (state.items.isEmpty) {
            return SmartRefresher(
              controller: _refreshCtrl,
              enablePullDown: true,
              enablePullUp: false,
              onRefresh: _onRefresh,
              header: const ClassicHeader(),
              child: const Center(child: Text('目前沒有提現紀錄')),
            );
          }

          // 有資料 -> SmartRefresher 包 ListView.separated
          return SmartRefresher
            (
            controller: _refreshCtrl,
            enablePullDown: true,
            enablePullUp: true,
            onRefresh: _onRefresh,
            onLoading: _onLoading,
            header: const ClassicHeader(),
            footer: CustomFooter(
              builder: (context, mode) {
                Widget body;
                if (mode == LoadStatus.loading) {
                  body = const SizedBox(
                    width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2),
                  );
                } else if (mode == LoadStatus.noMore) {
                  body = const Text('— 沒有更多 —', style: TextStyle(color: Colors.grey));
                } else if (mode == LoadStatus.failed) {
                  body = const Text('載入失敗，點擊重試', style: TextStyle(color: Colors.grey));
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
              itemCount: state.items.length, // ⚠️ 不再多加一個 loading row，交給 footer
              separatorBuilder: (_, __) => const Divider(
                height: 36,
                thickness: 1,
                color: Color(0xFFEDEDED),
              ),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: state.isLoading
                            ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator())
                            : const Text('— 没有更多 —', style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }

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
                        // (保持你原本左側/右側 UI 完全一致)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('提现到${_methodText(r)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              Text(_formatDate(r.createAt),
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
                            ],
                          ),
                        ),
                        Text(_formatAmount(r.amount), style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  );
                }
            ),
          );
        },
      ),
    );
  }
}