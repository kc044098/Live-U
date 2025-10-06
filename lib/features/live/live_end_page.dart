import 'dart:async';

import 'package:djs_live_stream/features/live/video_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../routes/app_routes.dart';
import 'data_model/live_end_summary.dart';

class LiveEndPage extends ConsumerStatefulWidget {
  const LiveEndPage({super.key});
  @override
  ConsumerState<LiveEndPage> createState() => _LiveEndPageState();
}

class _LiveEndPageState extends ConsumerState<LiveEndPage> {
  LiveEndSummary _s = const LiveEndSummary();
  String _roomId = '';
  Timer? _pollTimer;
  int _tries = 0;
  bool _inFlight = false;

  static const _interval = Duration(seconds: 1);
  static const _maxTries = 20; // 最多等 20 秒（可自行調整）
  static const _maxConsecMisses = 5;    // ★ 連續撈不到的上限
  int _consecMisses = 0;                // ★ 連續撈不到的次數

  @override
  void initState() {
    super.initState();
    // 等第一幀後再取 arguments，避免 context 炸掉
    WidgetsBinding.instance.addPostFrameCallback((_) => _initArgsAndMaybePoll());
  }

  void _initArgsAndMaybePoll() {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map) {
      _roomId = (args['roomId'] ?? '').toString();
      final initial = args['initial'];
      if (initial is LiveEndSummary) _s = initial;
    } else if (args is LiveEndSummary) {
      // 相容舊版：只傳物件也能顯示，但不能輪詢
      _s = args;
      _roomId = '';
    }

    setState(() {}); // 先畫初值（可能 liveUnix==0）

    if ((_s.liveUnix ?? 0) == 0 && _roomId.isNotEmpty) {
      _startPolling();
    }
  }

  String _fmtDuration(BuildContext context, int sec) {
    final t = S.of(context);
    if (sec <= 0) return t.durationZeroSeconds;
    final m = sec ~/ 60;
    final s = sec % 60;
    // 與原本「m分鐘s秒 / s秒」的樣式一致，只把單位交給語系字串
    return m > 0 ? '$m${t.minuteUnit}$s${t.secondUnit}' : '$s${t.secondUnit}';
  }

  void _startPolling() {
    _stopPolling();
    _tries = 0;
    _consecMisses = 0;      // ★ 重置
    _inFlight = false;

    _pollTimer = Timer.periodic(_interval, (t) async {
      if (!mounted) return;
      if (_inFlight) return;
      if (_tries++ >= _maxTries) { t.cancel(); return; }

      _inFlight = true;
      try {
        final fresh = await ref
            .read(videoRepositoryProvider)
            .fetchLiveEnd(channelName: _roomId);

        if (!mounted) return;

        if ((fresh.liveUnix ?? 0) > 0) {
          // 拿到結果 → 更新並停止輪詢
          setState(() => _s = fresh);
          _consecMisses = 0;
          t.cancel();
        } else {
          // ★ 沒拿到 → 累計「連續沒拿到」次數
          _consecMisses++;
          if (_consecMisses >= _maxConsecMisses) {
            t.cancel();
            _pollTimer = null;
            // 可選：給個提示
            // Fluttertoast.showToast(msg: '结算结果尚未生成，返回首页');
            if (mounted) {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            }
          }
        }
      } catch (e, st) {
        // ★ 發生錯誤也當成「沒拿到」來計數
        debugPrint('[live_end] poll error: $e\n$st');
        _consecMisses++;
        if (_consecMisses >= _maxConsecMisses) {
          t.cancel();
          _pollTimer = null;
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.home);
          }
        }
      } finally {
        _inFlight = false;
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context); // 取本地化資源
    final stillCalculating = (_s.liveUnix ?? 0) == 0;

    // 視頻/語音收入與對應標籤
    final bool isVideoIncome = (_s.videoGold ?? 0) > 0;
    final int callGold = isVideoIncome ? (_s.videoGold ?? 0) : (_s.voiceGold ?? 0);
    final String callLabel = isVideoIncome ? t.videoIncome : t.voiceIncome;
    final int totalGold = callGold + (_s.giftGold ?? 0);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(t.chatEndedTitle, style: const TextStyle(fontSize: 16, color: Colors.black)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
          ),
          actions: [
            if (stillCalculating && _roomId.isNotEmpty)
              IconButton(
                tooltip: t.refresh,
                icon: const Icon(Icons.refresh, color: Colors.black),
                onPressed: _startPolling,
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/pic_live_end.png',
                      width: 180, height: 180, fit: BoxFit.contain),
                  if (stillCalculating)
                    const SizedBox(
                      width: 48, height: 48,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 標題/副標
            Center(
              child: Text(
                stillCalculating ? t.settlingPleaseWait : t.greatJobKeepItUp,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${t.videoDurationPrefix}${_fmtDuration(context, _s.liveUnix ?? 0)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9A9A9A)),
              ),
            ),
            const SizedBox(height: 20),

            // 結算卡片
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _Metric(value: '$totalGold${t.coinUnit}', label: t.totalIncome),
                        const SizedBox(height: 16),
                        _Metric(value: '${_s.giftNum ?? 0}${t.timesUnit}', label: t.giftsCountLabel),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _Metric(value: '$callGold${t.coinUnit}', label: callLabel),
                        const SizedBox(height: 16),
                        _Metric(value: '${_s.giftGold ?? 0}${t.coinUnit}', label: t.giftIncome),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (stillCalculating && _roomId.isNotEmpty)
              Center(
                child: TextButton.icon(
                  onPressed: _startPolling,
                  icon: const Icon(Icons.refresh),
                  label: Text(t.stillNotSettledTapRetry),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9A9A9A),
          ),
        ),
      ],
    );
  }
}
