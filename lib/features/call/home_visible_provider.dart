import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 仅当“首页 LiveListPage 可见且在最上层”时为 true
final isLiveListVisibleProvider = StateProvider<bool>((_) => false);

class IncomingBannerData {
  final String channel;
  final int fromUid;
  final String name;
  final String avatarUrl;
  final String rtcToken; // 可能為空字串
  final int flag;        // 1=video, 2=voice
  const IncomingBannerData({
    required this.channel,
    required this.fromUid,
    required this.name,
    required this.avatarUrl,
    required this.rtcToken,
    required this.flag,
  });
}

// 當 != null 時，LiveListPage 疊一個 IncomingCallBanner
final incomingBannerProvider = StateProvider<IncomingBannerData?>((_) => null);
