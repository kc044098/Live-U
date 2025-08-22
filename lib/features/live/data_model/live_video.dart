// ✅ 影片資料（後端推薦流）
class LiveVideo {
  final String id;
  final String hlsUrl;
  final String coverUrl;      // 封面
  final String broadcasterId;
  final String broadcasterName;
  final String avatarUrl;
  final List<String> tags;
  final int pricePerMin;
  LiveVideo({
    required this.id,
    required this.hlsUrl,
    required this.coverUrl,
    required this.broadcasterId,
    required this.broadcasterName,
    required this.avatarUrl,
    required this.tags,
    required this.pricePerMin,
  });
}

// ✅ 視窗策略設定（可熱更新）
class PrefetchPolicy {
  final int ahead;       // +N
  final int behind;      // -N
  final int concurrency; // 同時下載數
  final Duration initWarmup; // 進場前多少時間初始化播放器
  const PrefetchPolicy({
    this.ahead = 2,
    this.behind = 1,
    this.concurrency = 2,
    this.initWarmup = const Duration(milliseconds: 250),
  });
}
