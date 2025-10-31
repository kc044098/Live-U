import 'dart:convert';

class ChatThreadItem {
  final String id;
  final int fromUid;
  final int toUid;
  final String? nickname;
  final List<String> avatars;    // 可能為空陣列
  final int status;
  final int unread;
  final int updateAt;            // epoch(second)
  final String lastText;         // 若是文字：content.chat_text
  final int vip;                 // vip 等級

  // ✅ 新增：保留原始 content 字串（JSON），以及語音資訊
  final String contentRaw;       // 原始 j['content'] 字串
  final bool lastIsVoice;        // 最後一筆是否為語音
  final int? lastVoiceDuration;  // 語音秒數（可能為 null）
  final bool lastIsImage;
  final String? lastImagePath;

  ChatThreadItem({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.nickname,
    required this.avatars,
    required this.status,
    required this.unread,
    required this.updateAt,
    required this.lastText,
    required this.vip,
    this.contentRaw = '',
    this.lastIsVoice = false,
    this.lastVoiceDuration,
    this.lastIsImage = false,
    this.lastImagePath,
  });

  factory ChatThreadItem.fromJson(Map<String, dynamic> j) {
    // 原始 content 先留一份
    final rawContent = (j['content'] ?? '').toString();

    String last = '';
    bool isVoice = false;
    int? voiceDur;

    bool isImage = false;
    String? imgPath;

    if (rawContent.isNotEmpty) {
      try {
        final c = jsonDecode(rawContent);
        if (c is Map) {
          final voicePath = c['voice_path']?.toString() ?? '';
          if (voicePath.isNotEmpty) {
            isVoice = true;
            final d = c['duration'];
            voiceDur = (d is num) ? d.toInt() : int.tryParse('$d');
          } else {
            // 圖片鍵名容錯：img_path / image_path
            imgPath = (c['img_path'] ?? c['image_path'])?.toString();
            if ((imgPath ?? '').isNotEmpty) {
              isImage = true;
              // 圖片就不設定 lastText，列表改顯示圖示+「圖片」
            } else {
              final chat = c['chat_text'];
              if (chat is String) last = chat;
            }
          }
        }
      } catch (_) {}
    }

    List<String> avas = [];
    if (j['avatar'] is List) {
      avas = (j['avatar'] as List).whereType<String>().toList();
    }

    return ChatThreadItem(
      id: (j['id'] ?? '').toString(),
      fromUid: (j['from_uid'] as num?)?.toInt() ?? 0,
      toUid: (j['to_uid'] as num?)?.toInt() ?? 0,
      nickname: (j['nick_name'])?.toString(),
      avatars: avas,
      status: (j['status'] as num?)?.toInt() ?? 0,
      unread: (j['unread'] as num?)?.toInt() ?? 0,
      updateAt: (j['update_at'] as num?)?.toInt() ?? 0,
      lastText: last,
      vip: (j['vip'] as num?)?.toInt() ?? 0,
      contentRaw: rawContent,
      lastIsVoice: isVoice,
      lastVoiceDuration: voiceDur,
      lastIsImage: isImage,
      lastImagePath: imgPath,
    );
  }
}

class ChatThreadPage {
  final List<ChatThreadItem> items;
  final int totalCount;
  ChatThreadPage({required this.items, required this.totalCount});
}
