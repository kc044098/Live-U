
enum MessageType {
  self,    // 自己發送
  other,   // 對方發送
  system,  // 系統訊息
}

enum ChatContentType {
  text,
  voice,
  call,
  system,
}

class ChatMessage {
  final MessageType type;
  final ChatContentType contentType;
  final String? text;
  final String? avatar;
  final String? audioPath;  // 語音檔案路徑
  final int? duration;      // 語音時長
  bool isPlaying;           // 是否正在播放
  int currentPosition;      // 用來顯示當前播放秒數

  ChatMessage({
    required this.type,
    required this.contentType,
    this.text,
    this.avatar,
    this.audioPath,
    this.duration,
    this.isPlaying = false,
    this.currentPosition = 0,
  });
}