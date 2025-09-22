// Live_End.dart
import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import 'data_model/live_end_summary.dart';

class LiveEndPage extends StatelessWidget {
  const LiveEndPage({super.key});

  String _fmtDuration(int sec) {
    if (sec <= 0) return '0秒';
    final m = sec ~/ 60;
    final s = sec % 60;
    return m > 0 ? '${m}分钟${s}秒' : '${s}秒';
  }

  @override
  Widget build(BuildContext context) {
    // 路由 arguments 帶進來的資料；若拿不到就給 0 值
    final s = (ModalRoute.of(context)?.settings.arguments is LiveEndSummary)
        ? ModalRoute.of(context)!.settings.arguments as LiveEndSummary
        : const LiveEndSummary();

    // 視頻/語音收入與對應標籤
    final bool isVideoIncome = (s.videoGold ?? 0) > 0;
    final int callGold = isVideoIncome ? (s.videoGold ?? 0) : (s.voiceGold ?? 0);
    final String callLabel = isVideoIncome ? '视频收入' : '语音收入';

    // 總收入 = 通話收入 + 禮物收入
    final int totalGold = (callGold) + (s.giftGold ?? 0);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('聊天结束',
              style: TextStyle(fontSize: 16, color: Colors.black)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.home),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Image.asset('assets/pic_live_end.png',
                  width: 180, height: 180, fit: BoxFit.contain),
            ),
            const SizedBox(height: 12),

            // 標題/副標
            const Center(
              child: Text(
                '太棒了，努力就会有收获！',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                '视频时长：${_fmtDuration(s.liveUnix ?? 0)}',
                style:
                const TextStyle(fontSize: 12, color: Color(0xFF9A9A9A)),
              ),
            ),
            const SizedBox(height: 20),

            // 結算卡片
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  // 左半：總收入 + 送禮次數  —— 置中
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _Metric(value: '${totalGold}金币', label: '总收入'),
                        const SizedBox(height: 16),
                        _Metric(value: '${s.giftNum ?? 0}次', label: '送礼次数'),
                      ],
                    ),
                  ),
                  // 右半：視頻/語音收入 + 禮物收入  —— 置中
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _Metric(value: '${callGold}金币', label: callLabel),
                        const SizedBox(height: 16),
                        _Metric(value: '${s.giftGold ?? 0}金币', label: '礼物收入'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// 置中顯示的單一指標
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
