import 'package:flutter/material.dart';

@immutable
class LiveEndSummary {
  final int giftGold;   // 禮物收入
  final int videoGold;  // 視頻收入
  final int voiceGold;  // 語音收入
  final int giftNum;    // 送禮次數
  final int liveUnix;   // 視頻/語音總時長（秒）

  const LiveEndSummary({
    this.giftGold = 0,
    this.videoGold = 0,
    this.voiceGold = 0,
    this.giftNum = 0,
    this.liveUnix = 0,
  });

  int get callGold => videoGold > 0 ? videoGold : voiceGold; // 擇一使用
  int get totalGold => callGold + giftGold;

  factory LiveEndSummary.fromJson(Map<String, dynamic> j) => LiveEndSummary(
    giftGold: (j['gift_gold'] ?? 0) as int,
    videoGold: (j['video_gold'] ?? 0) as int,
    voiceGold: (j['voice_gold'] ?? 0) as int,
    giftNum: (j['gift_num'] ?? 0) as int,
    liveUnix: (j['live_unix'] ?? 0) as int, // 後端欄位 LiveUnix
  );
}