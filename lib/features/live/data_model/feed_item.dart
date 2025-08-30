enum FeedKind { video, image }
enum OnlineStatus { offline, online, busy, unknown }

class FeedItem {
  final int id;                // 影片 ID
  final int uid;               // 影片擁有者的用戶 ID
  final String? videoUrl;      // 絕對 URL
  final List<String> images;   // 絕對 URL
  final String title;

  final String? nickName;
  final List<String> avatar;
  final List<String> tags;

  /// 後端的原始 is_like 整數（例如 1=已讚 / 2=未讚）
  final int isLike;

  /// 讚數
  final int? likes;
  final double? pricePerMinute;

  final int? onlineStatusRaw;

  FeedItem({
    required this.id,
    required this.uid,
    required this.title,
    this.videoUrl,
    this.images = const [],
    this.nickName,
    this.avatar = const [],
    this.tags = const [],
    this.isLike = 0,
    this.likes,
    this.pricePerMinute,
    this.onlineStatusRaw,
  });

  FeedKind get kind =>
      (videoUrl != null && videoUrl!.isNotEmpty) ? FeedKind.video : FeedKind.image;

  /// 封面來源：若有 img 用第一張
  String? get coverCandidate => images.isNotEmpty ? images.first : null;

  /// 取第一張大頭照
  String? get firstAvatar => avatar.isNotEmpty ? avatar.first : null;

  static FeedItem fromJson(Map<String, dynamic> j, {String? cdnBaseUrl}) {
    String toFullUrl(String path) {
      if (path.startsWith('http')) return path;
      if (cdnBaseUrl != null) return '$cdnBaseUrl$path';
      return path;
    }

    List<String> parseImages(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .map((p) => toFullUrl(p))
            .toList();
      } else if (raw is String && raw.isNotEmpty) {
        return [toFullUrl(raw)];
      }
      return [];
    }

    List<String> parseTags(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (raw is String && raw.isNotEmpty) {
        return raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    List<String> parseAvatarList(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .map((p) => toFullUrl(p))
            .toList();
      } else if (raw is String && raw.isNotEmpty) {
        return [toFullUrl(raw)];
      }
      return [];
    }

    final int? status = j['status'] == null ? null : int.tryParse(j['status'].toString());

    return FeedItem(
      id: j['id'] is int ? j['id'] : int.tryParse(j['id']?.toString() ?? '') ?? 0,
      uid: j['uid'] is int ? j['uid'] : int.tryParse(j['uid']?.toString() ?? '') ?? 0,
      title: j['title']?.toString() ?? '',
      videoUrl: (j['video_url']?.toString().isNotEmpty ?? false)
          ? toFullUrl(j['video_url'].toString())
          : null,
      images: parseImages(j['img']),
      nickName: j['nick_name']?.toString(),
      avatar: parseAvatarList(j['avatar']),
      tags: parseTags(j['tags']),
      isLike: int.tryParse(j['is_like']?.toString() ?? '') ?? 0,
      likes: j['likes'] == null ? null : int.tryParse(j['likes'].toString()),
      pricePerMinute: double.tryParse(j['price']),
      onlineStatusRaw: status,
    );
  }

  OnlineStatus get onlineStatus {
    final s = onlineStatusRaw;
    if (s == null) return OnlineStatus.unknown;
    if (s == 0) return OnlineStatus.offline;
    if (s == 3) return OnlineStatus.busy;
    if (s == 1 || s == 2) return OnlineStatus.online;
    return OnlineStatus.unknown;
  }

  FeedItem copyWith({int? isLike, int? likes, int? onlineStatusRaw}) {
    return FeedItem(
      id: id,
      uid: uid,
      title: title,
      videoUrl: videoUrl,
      images: images,
      nickName: nickName,
      avatar: avatar,
      tags: tags,
      isLike: isLike ?? this.isLike,
      likes: likes ?? this.likes,
      pricePerMinute: pricePerMinute,
      onlineStatusRaw: onlineStatusRaw ?? this.onlineStatusRaw,
    );
  }
}