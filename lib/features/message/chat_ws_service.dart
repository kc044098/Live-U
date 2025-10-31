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

  Map<String, dynamic>? decodeJsonMap(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final v = jsonDecode(s);
      if (v is Map) return v.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {}
    return null;
  }

  int? toInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}');
  }

  String joinCdn(String base, String path) {
    if (path.isEmpty || path.startsWith('http')) return path;
    final b = base.replaceFirst(RegExp(r'/+$'), '');
    final p = path.replaceFirst(RegExp(r'^/+'), '');
    return '$b/$p';
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
    final st = pick<int>(data, ['Status','status']);
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

    // 第一層：content -> Map（含 chat_text / voice_path）
    Map<String, dynamic>? cjson = decodeJsonMap(content);
    String? chatText;
    String? translateText;
    String? voiceRel;
    int duration = 0;

    if (cjson != null) {
      chatText = (cjson['chat_text'] ?? '').toString();
      translateText = (cjson['translate_chat_text'] ?? '').toString();
      voiceRel = (cjson['voice_path'] ?? '').toString();
      final dRaw = cjson['duration'];
      duration = (dRaw is num) ? dRaw.toInt() : int.tryParse('${dRaw ?? ''}') ?? 0;
      if ((chatText ?? '').isEmpty && (voiceRel ?? '').isEmpty) {
        chatText = content;
      }
    } else {
      chatText = content;
    }

    // 禮物
    final inner = decodeJsonMap(chatText);
    final t = (inner?['type'] ?? inner?['t'])?.toString().toLowerCase();
    if (t == 'gift') {
      final id    = () { final v = inner?['gift_id'] ?? inner?['id']; if (v is num) return v.toInt(); return int.tryParse('$v') ?? -1; }();
      final title = (inner?['gift_title'] ?? inner?['title'] ?? '').toString();
      final iconRel = (inner?['gift_icon'] ?? inner?['icon'] ?? '').toString();
      final gold  = () { final v = inner?['gift_gold'] ?? inner?['gold']; if (v is num) return v.toInt(); return int.tryParse('$v') ?? 0; }();
      final count = () { final v = inner?['gift_count'] ?? inner?['count']; if (v is num) return v.toInt(); return int.tryParse('$v') ?? 1; }();
      final giftUrlRel = (inner?['gift_url'] ?? '').toString();

      final iconFull = joinCdn(cdnBase, iconRel);
      final giftUrlFull = joinCdn(cdnBase, giftUrlRel);

      return ChatMessage(
        type: MessageType.other,
        contentType: ChatContentType.gift,
        text: title,
        uuid: uuid.isEmpty ? null : uuid,
        createAt: createAt,
        readStatus: st,
        data: {
          'gift_id'   : id,
          'gift_title': title,
          'gift_icon' : iconFull,
          'gift_gold' : gold,
          'gift_count': count,
          if (giftUrlRel.isNotEmpty) 'gift_url': giftUrlFull,
        },
      );
    }

    final imgRel1 = (cjson?['img_path'] ?? cjson?['image_path'])?.toString() ?? '';
    final imgRel2 = (inner?['img_path'] ?? inner?['image_path'])?.toString() ?? '';
    final imgRel  = imgRel1.isNotEmpty ? imgRel1 : imgRel2;

    // 圖片
    if (imgRel.isNotEmpty) {
      return ChatMessage(
        type: MessageType.other,
        contentType: ChatContentType.image,
        imagePath: joinCdn(cdnBase, imgRel), // 轉完整 URL
        uuid: uuid.isEmpty ? null : uuid,
        createAt: createAt,
        readStatus: st,
      );
    }

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

    // 語音
    if ((voiceRel ?? '').isNotEmpty) {
      return ChatMessage(
        type: MessageType.other,
        contentType: ChatContentType.voice,
        audioPath: joinCdn(cdnBase, voiceRel!),
        duration: duration,
        uuid: uuid.isEmpty ? null : uuid,
        createAt: createAt,
        readStatus: st,
      );
    }

    // 純文字
    return ChatMessage(
      type: MessageType.other,
      contentType: ChatContentType.text,
      text: chatText ?? '',
      translate_text: translateText,
      uuid: uuid.isEmpty ? null : uuid,
      createAt: createAt,
      readStatus: st,
    );
  }
}

class ReadReceipt {
  final String uuid;     // 後端帶的最後一條消息 id（可選）
  final int createAt;    // 後端帶的時間（秒，若沒有就 0）
  final int fromUid;     // 對方 uid
  final int toUid;       // 我方 uid
  ReadReceipt({required this.uuid, required this.createAt, required this.fromUid, required this.toUid});
}

extension _ChatWsServiceReads on ChatWsService {
  // 監聽「某個對話伙伴」的已讀回執
  Stream<ReadReceipt> roomReadStream({required int partnerUid}) {
    final ws   = _ref.read(wsProvider);
    final me   = _ref.read(userProfileProvider);
    final myUid = int.tryParse(me?.uid ?? '') ?? -1;

    ws.ensureConnected();

    final controller = StreamController<ReadReceipt>(sync: true);

    // 如果你的 ws 有命名事件（例如 'room_read' 或 'message.read'），用它優先：
    final unsubNamed = ws.on('room_read', (payload) {
      final rec = _parseReadReceiptFromMap(payload);
      if (rec != null && rec.fromUid == partnerUid && rec.toUid == myUid) {
        controller.add(rec);
      }
    });

    // 保底：若後端沒有獨立事件、只丟「flag:9」的廣播，就用 tapRaw 抓
    final untap = ws.tapRaw((raw) {
      try {
        String? text;
        if (raw is String) text = raw;
        if (raw is List<int>) text = utf8.decode(raw, allowMalformed: true);
        if (text == null || text.isEmpty) return;

        final m = jsonDecode(text);
        if (m is! Map) return;

        int? pickInt(dynamic v) {
          if (v is num) return v.toInt();
          return int.tryParse('${v ?? ''}');
        }
        T? pick<T>(Map mm, List<String> keys) {
          for (final k in keys) {
            if (!mm.containsKey(k)) continue;
            final v = mm[k];
            if (T == int || T == num) return (pickInt(v) as T?);
            return v as T?;
          }
          return null;
        }

        final flag = pick<int>(m, ['flag','Flag','type','Type']);
        if (flag != 9) return;

        // 兼容 data/Data
        final Map data = (m['data'] is Map) ? m['data'] as Map
            : (m['Data'] is Map) ? m['Data'] as Map
            : const {};

        final from = pick<int>(m, ['uid','Uid']) ?? pick<int>(data, ['uid','Uid']) ?? -1;
        final to   = pick<int>(m, ['to_uid','ToUid','toUid']) ?? pick<int>(data, ['to_uid','ToUid','toUid']) ?? -1;
        final uuid = pick<String>(m, ['uuid','UUID']) ?? pick<String>(data, ['uuid','UUID','id','Id']) ?? '';
        final ts   = pick<int>(data, ['create_at','CreateAt','update_at','UpdateAt']) ?? 0;

        if (from == partnerUid && to == myUid) {
          controller.add(ReadReceipt(uuid: uuid ?? '', createAt: ts, fromUid: from, toUid: to));
        }
      } catch (_) {}
    });

    controller.onCancel = () {
      try { unsubNamed(); } catch (_) {}
      try { untap(); } catch (_) {}
    };

    return controller.stream;
  }

  ReadReceipt? _parseReadReceiptFromMap(Map payload) {
    int? _i(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v');
    T? pick<T>(Map m, List<String> ks) {
      for (final k in ks) {
        if (m.containsKey(k)) {
          final v = m[k];
          if (T == int || T == num) return (_i(v) as T?);
          return v as T?;
        }
      }
      return null;
    }

    final Map data = (payload['data'] is Map) ? payload['data']
        : (payload['Data'] is Map) ? payload['Data']
        : const {};
    final flag = pick<int>(payload, ['flag','Flag','type','Type']);
    if (flag != 9) return null;

    final uuid = pick<String>(payload, ['uuid','UUID']) ?? pick<String>(data, ['id','Id','uuid','UUID']) ?? '';
    final from = pick<int>(payload, ['uid','Uid']) ?? pick<int>(data, ['uid','Uid']) ?? -1;
    final to   = pick<int>(payload, ['to_uid','ToUid','toUid']) ?? pick<int>(data, ['to_uid','ToUid','toUid']) ?? -1;
    final ts   = pick<int>(data, ['create_at','CreateAt','update_at','UpdateAt']) ?? 0;

    return ReadReceipt(uuid: uuid, createAt: ts, fromUid: from, toUid: to);
  }

  Stream<void> inboxBumpStream() {
    final ws   = _ref.read(wsProvider);
    final me   = _ref.read(userProfileProvider);
    final myUid = int.tryParse(me?.uid ?? '') ?? -1;

    ws.ensureConnected();

    final controller = StreamController<void>(sync: true);

    // 命名事件（優先用）
    final unsubRoom = ws.on('room_chat', (payload) {
      try {
        final Map data = (payload['data'] is Map)
            ? payload['data']
            : (payload['Data'] is Map)
            ? payload['Data']
            : const {};

        // 只在「跟我有關」的訊息時觸發（你想更嚴格可改成：只要 toUid==myUid）
        final fromUid = (data['Uid'] ?? data['uid'])?.toString() ?? '';
        final toUid   = (data['ToUid'] ?? data['to_uid'] ?? data['toUid'])?.toString() ?? '';
        if (fromUid.isEmpty && toUid.isEmpty) return;

        // 有效 → 通知
        controller.add(null);
      } catch (_) {}
    });

    // 保底：若伺服器沒命名事件，只丟 raw
    final untap = ws.tapRaw((raw) {
      try {
        String? text;
        if (raw is String) text = raw;
        if (raw is List<int>) text = utf8.decode(raw, allowMalformed: true);
        if (text == null || text.isEmpty) return;

        // 這裡與你的 RAW 偵錯規則保持一致（type:8 或 type:"room_chat"）
        if (text.contains('"type":8') ||
            text.contains('"Type":8') ||
            text.contains('"type":"room_chat"')) {
          controller.add(null);
        }
      } catch (_) {}
    });

    controller.onCancel = () {
      try { unsubRoom(); } catch (_) {}
      try { untap(); } catch (_) {}
    };

    return controller.stream;
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

final roomReadProvider = StreamProvider.autoDispose
    .family<ReadReceipt, int>((ref, partnerUid) {
  final svc = ref.read(chatWsServiceProvider);
  return svc.roomReadStream(partnerUid: partnerUid);
});

final inboxBumpProvider = StreamProvider.autoDispose<void>((ref) {
  final svc = ref.read(chatWsServiceProvider);
  return svc.inboxBumpStream();
});