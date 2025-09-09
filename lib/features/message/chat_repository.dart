import 'dart:convert';

import '../../data/network/api_client.dart';
import '../../data/network/api_endpoints.dart';
import 'chat_thread_item.dart';

class ChatRepository {
  ChatRepository(this._api);
  final ApiClient _api;

  /// 發送文字訊息
  /// 回傳 true=成功, false=失敗
  Future<bool> sendText({
    required String uuid,
    required int toUid,
    required String text,
    String flag = 'chat_person',
  }) async {
    final payload = {
      "data": {"chat_text": text},
      "flag": flag,
      "to_uid": toUid,
      "uuid": uuid,
    };

    final resp = await _api.post(ApiEndpoints.messageSend, data: payload);
    try {
      if (resp.data is Map && resp.data['code'] == 200) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendVoice({
    required String uuid,
    required int toUid,
    required String voicePath,
    required String durationSec,
    String flag = 'chat_person',
  }) async {
    final payload = {
      "data": {
        "voice_path": voicePath,
        if (durationSec != null) "duration": durationSec,
      },
      "flag": flag,
      "to_uid": toUid,
      "uuid": uuid,
    };

    final resp = await _api.post(ApiEndpoints.messageSend, data: payload);
    try {
      final data = resp.data is Map ? resp.data as Map : {};
      return data['code'] == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendImage({
    required String uuid,
    required int toUid,
    required String imagePath, // ← S3 相對路徑
    int? width,
    int? height,
    String flag = 'chat_person',
  }) async {
    final payload = {
      "data": {
        "img_path": imagePath,
      },
      "flag": flag,
      "to_uid": toUid,
      "uuid": uuid,
    };

    final resp = await _api.post(ApiEndpoints.messageSend, data: payload);
    try {
      final data = resp.data is Map ? resp.data as Map : {};
      return data['code'] == 200;
    } catch (_) {
      return false;
    }
  }

  /// 取得歷史聊天訊息（分頁）
  Future<List<Map<String, dynamic>>> fetchMessageHistory({
    required int page,
    required int toUid,
  }) async {
    final resp = await _api.post(ApiEndpoints.messageHistory, data: {
      "page": page,
      "to_uid": toUid,
    });

    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;
    if (raw is! Map) {
      throw Exception('拉取歷史失敗: 非預期回應');
    }

    // ① 處理「沒有資料」
    final code = raw['code'] is num
        ? (raw['code'] as num).toInt()
        : int.tryParse('${raw['code']}') ?? -1;
    final msg  = '${raw['message'] ?? ''}';
    if (code == 100 && msg.toLowerCase().contains('not found')) {
      return <Map<String, dynamic>>[]; // ← 當作空資料
    }

    // ② 其它錯誤照舊丟出
    if (code != 200) {
      throw Exception('拉取歷史失敗: ${msg.isEmpty ? 'unknown' : msg}');
    }

    // ③ 正常解析 + 過濾 + 去重
    final items = (raw['data']?['list'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((m) {
      final id  = '${m['id'] ?? ''}'.trim();
      final rid = '${m['request_id'] ?? ''}'.trim();
      return id.isNotEmpty && rid.isNotEmpty;
    });

    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (final m in items) {
      final key = '${m['request_id']}';
      if (seen.add(key)) deduped.add(m);
    }
    return deduped;
  }



  Future<ChatThreadPage> fetchUserMessageList({int page = 1}) async {
    final resp = await _api.post(ApiEndpoints.userMessageList, data: {"page": page});
    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;

    // 處理「沒有資料」
    final code = raw['code'] is num
        ? (raw['code'] as num).toInt()
        : int.tryParse('${raw['code']}') ?? -1;
    final msg  = '${raw['message'] ?? ''}';
    if (code == 100 && msg.toLowerCase().contains('not found')) {
      return ChatThreadPage(items: [], totalCount: 0); // ← 當作空資料
    }

    if (raw is! Map || raw['code'] != 200 || raw['data'] == null) {
      throw Exception('載入失敗: ${raw is Map ? (raw['message'] ?? '未知錯誤') : '非預期回應'}');
    }

    final data = Map<String, dynamic>.from(raw['data']);
    final list = (data['list'] as List? ?? [])
        .map((e) => ChatThreadItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final count = (data['count'] as num?)?.toInt() ?? list.length;

    return ChatThreadPage(items: list, totalCount: count);
  }

  String _guessMime(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      case 'gif':  return 'image/gif';
      case 'mp4':  return 'video/mp4';
      case 'mov':  return 'video/quicktime';
      case 'm4a':  return 'audio/mp4';
      case 'aac':  return 'audio/aac';
      case 'mp3':  return 'audio/mpeg';
      case 'wav':  return 'audio/wav';
      case 'amr':  return 'audio/amr';
      case 'ogg':  return 'audio/ogg';
      case 'opus': return 'audio/opus';
      default:     return 'application/octet-stream';
    }
  }
}




