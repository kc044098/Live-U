
class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String coverEmoji;        // 先用 emoji 當頭像示意
  final String path;              // 真正要回傳給預覽頁的音樂路徑
  bool isFavorited;
  bool usedBefore;
  final bool recommended;

  MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.coverEmoji,
    required this.path,
    this.isFavorited = false,
    this.usedBefore = false,
    this.recommended = false,
  });
}
