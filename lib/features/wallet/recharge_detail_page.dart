import 'dart:ui';

import 'package:djs_live_stream/features/wallet/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'model/recharge_detail.dart';

class RechargeDetailPage extends ConsumerStatefulWidget {
  final int oId; // 帳變 的 o_id
  const RechargeDetailPage({super.key, required this.oId});

  @override
  ConsumerState<RechargeDetailPage> createState() => _RechargeDetailPageState();
}

class _RechargeDetailPageState extends ConsumerState<RechargeDetailPage> {
  AsyncValue<RechargeDetail>? _detail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = ref.read(walletRepositoryProvider);
      setState(() {
        _detail = const AsyncValue.loading();
      });
      try {
        final d = await repo.fetchRechargeDetail(id: widget.oId);
        if (!mounted) return;
        setState(() => _detail = AsyncValue.data(d));
      } catch (e, st) {
        if (!mounted) return;
        setState(() => _detail = AsyncValue.error(e, st));
      }
    });
  }

  String _fmtTime(int ts) {
    if (ts <= 0) return '-';
    return DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(DateTime.fromMillisecondsSinceEpoch(ts * 1000));
  }

  String _statusText(int s) => switch (s) { 2 => '充值成功', 1 => '處理中', 3 => '充值失敗', _ => '未知狀態' };
  Color  _statusColor(int s) => switch (s) { 2 => const Color(0xFFFF4D67), 1 => Colors.orange, 3 => Colors.red, _ => Colors.grey };

  @override
  Widget build(BuildContext context) {
    final d = _detail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('帳單詳情', style: TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: d == null || d.isLoading
          ? const Center(child: CircularProgressIndicator())
          : d.when(
        data: (rd) => _buildBody(rd),
        error: (e, _) => _ErrorView(
          message: '$e',
          onRetry: () {
            setState(() => _detail = const AsyncValue.loading());
            final repo = ref.read(walletRepositoryProvider);
            repo.fetchRechargeDetail(id: widget.oId).then((rd) {
              if (!mounted) return;
              setState(() => _detail = AsyncValue.data(rd));
            }).catchError((err, st) {
              if (!mounted) return;
              setState(() => _detail = AsyncValue.error(err, st));
            });
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildBody(RechargeDetail d) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      child: Column(
        children: [
          // 上方圓形圖示 + 標題
          Container(
            width: 120, height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFF8AA8), Color(0xFFFF6A8E)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(child: Icon(Icons.savings, color: Colors.white, size: 56)),
          ),
          const SizedBox(height: 16),
          const Text('充值 - 金幣', style: TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 8),

          // 金額
          Text(d.amount.toStringAsFixed(2),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w600)),

          const SizedBox(height: 8),
          Text(_statusText(d.status), style: TextStyle(fontSize: 14, color: _statusColor(d.status))),
          const SizedBox(height: 24),
          const Divider(),

          // 明細項
          _kvRow('充值詳情', '\$ ${d.amount.toStringAsFixed(2)}'),
          _kvRow('充值金幣', '${d.gold} 個'),
          _kvRow('充值方式', d.channelCode.isNotEmpty ? d.channelCode : (d.remark.isNotEmpty ? d.remark : '充值')),
          _kvRow('充值時間', _fmtTime(d.createAt)),
          _kvRow('充值單號', d.orderNumber),
        ],
      ),
    );
  }

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: const TextStyle(color: Colors.black45, fontSize: 14)),
          ),
          Text(v, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('重試')),
          ],
        ),
      ),
    );
  }
}