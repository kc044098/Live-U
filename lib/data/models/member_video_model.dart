class MemberVideoModel {
  final int id;
  final String videoUrl;   // 可能是相對路徑，如 /image/xxx.mp4 或 /video/xxx.jpg
  final String? coverUrl;  // 可能為 null（若 img 有值，取第一張）
  final String title;
  final int isTop;   // 1=精選, 2=日常
  final int isShow;  // 1=上架
  final int isLike;  // 0/1
  final int updateAt;

  MemberVideoModel({
    required this.id,
    required this.videoUrl,
    required this.title,
    required this.isTop,
    required this.isShow,
    required this.isLike,
    required this.updateAt,
    this.coverUrl,
  });

  factory MemberVideoModel.fromJson(Map<String, dynamic> m) {
    String? parseFirstImg(dynamic v) {
      if (v == null) return null;
      if (v is List && v.isNotEmpty) {
        final first = v.first;
        return first == null ? null : first.toString();
      }
      if (v is String && v.isNotEmpty) {
        // 萬一後端回的是單一字串（少見），也支援
        return v;
      }
      return null;
    }

    return MemberVideoModel(
      id: m['id'] as int,
      videoUrl: (m['video_url'] ?? '').toString(),
      coverUrl: parseFirstImg(m['img']),
      title: (m['title'] ?? '').toString(),
      isTop: (m['is_top'] ?? 0) as int,
      isShow: (m['is_show'] ?? 0) as int,
      isLike: (m['is_like'] ?? 0) as int,
      updateAt: (m['update_at'] ?? 0) as int,
    );
  }

  MemberVideoModel copyWith({
    String? title,
    int? isTop,
    String? videoUrl,
    String? coverUrl,
    int? isShow,
    int? isLike,
    int? updateAt,
  }) {
    return MemberVideoModel(
      id: id,
      videoUrl: videoUrl ?? this.videoUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      title: title ?? this.title,
      isTop: isTop ?? this.isTop,
      isShow: isShow ?? this.isShow,
      isLike: isLike ?? this.isLike,
      updateAt: updateAt ?? this.updateAt,
    );
  }

  // 判斷是否為影片，考慮多種常見影片副檔名（含 iOS 上傳格式）
  bool get isVideo {
    final lower = videoUrl.toLowerCase();
    const videoExts = ['.mp4', '.mov', '.m4v', '.avi', '.wmv', '.flv', '.webm'];
    return videoExts.any((ext) => lower.endsWith(ext));
  }

  // 方便 UI：純圖片貼文（video_url 可能為空，但 coverUrl 有值）
  bool get isImage => !isVideo && (coverUrl != null && coverUrl!.isNotEmpty);

  // 轉絕對網址（帶上 baseUrl 或 cdnUrl）
  MemberVideoModel withAbsoluteUrls(String baseUrl) {
    String _abs(String? p) {
      if (p == null || p.isEmpty) return '';
      if (p.startsWith('http')) return p;
      if (!baseUrl.endsWith('/') && !p.startsWith('/')) return '$baseUrl/$p';
      if (baseUrl.endsWith('/') && p.startsWith('/')) return '$baseUrl${p.substring(1)}';
      return '$baseUrl$p';
    }

    final absVideo = _abs(videoUrl);
    final absCover = coverUrl == null ? null : _abs(coverUrl);

    return MemberVideoModel(
      id: id,
      videoUrl: absVideo,
      coverUrl: absCover,
      title: title,
      isTop: isTop,
      isShow: isShow,
      isLike: isLike,
      updateAt: updateAt,
    );
  }

}

// 分頁回應包
class MemberVideoPage {
  final List<MemberVideoModel> list;
  final int count; // 總數

  MemberVideoPage({required this.list, required this.count});

  bool get isEmpty => list.isEmpty;
}
