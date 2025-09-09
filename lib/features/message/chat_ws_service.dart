import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ws/ws_provider.dart';
import '../profile/profile_controller.dart';
import 'chat_message.dart';

class ChatWsService {
  ChatWsService(this._ref);
  final Ref _ref;

  // 專門提供某個對話（partnerUid）的即時訊息流
  Stream<ChatMessage> roomChatStream({required int partnerUid}) {
    final ws  = _ref.read(wsProvider);
    final me  = _ref.read(userProfileProvider);
    final cdn = me?.cdnUrl ?? '';
    final myUid = int.tryParse(me?.uid ?? '') ?? -1;

    ws.ensureConnected();

    final controller = StreamController<ChatMessage>(sync: true);
    final seenUuid = <String>{};

    // 低階訂閱：room_chat
    final unsubRoom = ws.on('room_chat', (payload) {
      final msg = _parseRoomChat(
        payload,
        myUid: myUid,
        partnerUid: partnerUid,
        cdnBase: cdn,
      );
      if (msg == null) return;

      // 去重（防重放）
      final u = msg.uuid ?? '';
      if (u.isNotEmpty && !seenUuid.add(u)) return;

      controller.add(msg);
    });

    // 可選：原始封包偵錯
    final untap = ws.tapRaw((raw) {
      try {
        String? text;
        if (raw is String) text = raw;
        if (raw is List<int>) text = utf8.decode(raw, allowMalformed: true);
        if (text == null || text.isEmpty) return;
        if (text.contains('"type":8') || text.contains('"Type":8') || text.contains('"type":"room_chat"')) {
          debugPrint('🧾[WS RAW room_chat] ${text.length > 2000 ? text.substring(0, 2000) + '…' : text}');
        }
      } catch (_) {}
    });

    controller.onCancel = () {
      try { unsubRoom(); } catch (_) {}
      try { untap(); } catch (_) {}
    };

    return controller.stream;
  }

  // === 封裝解析：把協議 -> ChatMessage ===
  ChatMessage? _parseRoomChat(
      Map<String, dynamic> payload, {
        required int myUid,
        required int partnerUid,
        required String cdnBase,
      }) {
    // 兼容 data/Data
    final Map<String, dynamic> data =
    (payload['Data'] is Map)
        ? Map<String, dynamic>.from(payload['Data'])
        : (payload['data'] is Map)
        ? Map<String, dynamic>.from(payload['data'])
        : const <String, dynamic>{};

    T? pick<T>(Map m, List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v != null) {
          if (T == int || T == num) {
            if (v is num) return v.toInt() as T;
            final n = int.tryParse(v.toString());
            if (n != null) return n as T;
          } else {
            return v as T;
          }
        }
      }
      return null;
    }

    String _s(dynamic v) => v?.toString() ?? '';

    final uuid    = pick<String>(payload, ['UUID','uuid']) ??
        pick<String>(data,    ['Id','id','UUID','uuid']) ?? '';

    final fromUid = pick<int>(payload, ['Uid','uid']) ??
        pick<int>(data,    ['Uid','uid']) ?? -1;

    final toUid   = pick<int>(payload, ['ToUid','to_uid','toUid']) ??
        pick<int>(data,    ['ToUid','to_uid','toUid']) ?? -1;

    final content = pick<String>(data, ['Content','content']) ?? '';

    final createAt = (() {
      final v = pick<int>(data, ['CreateAt','create_at','UpdateAt','update_at']);
      return (v ?? 0) > 0 ? v! : DateTime.now().millisecondsSinceEpoch ~/ 1000;
    })();

    // 只處理「對方 → 我」且為指定會話
    if (toUid != myUid || fromUid != partnerUid) return null;

    // 內容可能是 JSON
    Map<String, dynamic>? cjson;
    if (content.isNotEmpty) {
      try {
        final obj = jsonDecode(content);
        if (obj is Map) cjson = obj.map((k, v) => MapEntry(k.toString(), v));
      } catch (_) {}
    }

    String? chatText;
    String? voiceRel;
    int duration = 0;

    if (cjson != null) {
      chatText = _s(cjson['chat_text']);
      voiceRel = _s(cjson['voice_path']);
      final dRaw = cjson['duration'];
      duration = (dRaw is num) ? dRaw.toInt() : int.tryParse(_s(dRaw)) ?? 0;
      if ((chatText ?? '').isEmpty && (voiceRel ?? '').isEmpty) {
        chatText = content; // 純文字 fallback
      }
    } else {
      chatText = content;
    }

    String _joinCdn(String base, String path) {
      if (path.isEmpty || path.startsWith('http')) return path;
      final b = base.replaceFirst(RegExp(r'/+$'), '');
      final p = path.replaceFirst(RegExp(r'^/+'), '');
      return '$b/$p';
    }

    // 回傳 ChatMessage（封裝協議差異）
    if ((voiceRel ?? '').isNotEmpty) {
      return ChatMessage(
        type: MessageType.other,
        contentType: ChatContentType.voice,
        audioPath: _joinCdn(cdnBase, voiceRel!),
        duration: duration,
        uuid: uuid.isEmpty ? null : uuid,
        createAt: createAt,
      );
    }

    return ChatMessage(
      type: MessageType.other,
      contentType: ChatContentType.text,
      text: chatText ?? '',
      uuid: uuid.isEmpty ? null : uuid,
      createAt: createAt,
    );
  }
}

// === Riverpod providers ===

final chatWsServiceProvider = Provider<ChatWsService>((ref) => ChatWsService(ref));

// 針對特定 partnerUid 的即時訊息流
final roomChatProvider = StreamProvider.autoDispose
    .family<ChatMessage, int>((ref, partnerUid) {
  final svc = ref.read(chatWsServiceProvider);
  return svc.roomChatStream(partnerUid: partnerUid);
});
