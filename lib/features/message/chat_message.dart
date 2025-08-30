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

enum SendState { sending, sent, failed }

class ChatMessage {
  // === 你原本就有的欄位（保持不變） ===
  final MessageType type;
  final ChatContentType contentType;
  final String? text;
  final String? avatar;
  final String? audioPath;
  final int? duration;
  bool isPlaying;
  int currentPosition;

  // === ✅ 新增協議欄位（全部可選） ===
  final String? uuid;                 // 後端協議用訊息ID
  final String? flag;                 // 例如 "chat_person"
  final int? toUid;                   // 對方 uid
  final Map<String, dynamic>? data;   // 送後端 data map
  final SendState? sendState;         // 送出中/成功/失敗

  ChatMessage({
    // 原本參數...
    required this.type,
    required this.contentType,
    this.text,
    this.avatar,
    this.audioPath,
    this.duration,
    this.isPlaying = false,
    this.currentPosition = 0,

    // 新增參數（可選）
    this.uuid,
    this.flag,
    this.toUid,
    this.data,
    this.sendState,
  });

  // ✅ 方便更新用
  ChatMessage copyWith({
    String? uuid,
    String? flag,
    int? toUid,
    Map<String, dynamic>? data,
    SendState? sendState,
    MessageType? type,
    ChatContentType? contentType,
    String? text,
    String? avatar,
    String? audioPath,
    int? duration,
    bool? isPlaying,
    int? currentPosition,
  }) {
    return ChatMessage(
      type: type ?? this.type,
      contentType: contentType ?? this.contentType,
      text: text ?? this.text,
      avatar: avatar ?? this.avatar,
      audioPath: audioPath ?? this.audioPath,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      uuid: uuid ?? this.uuid,
      flag: flag ?? this.flag,
      toUid: toUid ?? this.toUid,
      data: data ?? this.data,
      sendState: sendState ?? this.sendState,
    );
  }
}