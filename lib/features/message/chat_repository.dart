import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../data/network/api_client.dart';
import '../../data/network/api_endpoints.dart';
import 'chat_thread_item.dart';
import 'data_model/call_record_item.dart';

class ChatRepository {
  ChatRepository(this._api);
  final ApiClient _api;

  /// 發送文字訊息
  /// 回傳 true=成功, false=失敗
  // 改成回傳 SendResult（文字）
  Future<SendResult> sendText({
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
    final (code, msg) = _parseCodeMsg(resp.data);
    return SendResult(ok: code == 200, code: code, message: msg);
  }

  Future<SendResult> sendVoice({
    required String uuid,
    required int toUid,
    required String voicePath,
    required String durationSec,
    String flag = 'chat_person',
  }) async {
    final payload = {
      "data": {
        "voice_path": voicePath,
        "duration": durationSec,
      },
      "flag": flag,
      "to_uid": toUid,
      "uuid": uuid,
    };
    final resp = await _api.post(ApiEndpoints.messageSend, data: payload);
    final (code, msg) = _parseCodeMsg(resp.data);
    return SendResult(ok: code == 200, code: code, message: msg);
  }

  // 改成回傳 SendResult（圖片）
  Future<SendResult> sendImage({
    required String uuid,
    required int toUid,
    required String imagePath, // S3 相對路徑
    int? width,
    int? height,
    String flag = 'chat_person',
  }) async {
    final payload = {
      "data": {"img_path": imagePath},
      "flag": flag,
      "to_uid": toUid,
      "uuid": uuid,
    };
    final resp = await _api.post(ApiEndpoints.messageSend, data: payload);
    final (code, msg) = _parseCodeMsg(resp.data);
    return SendResult(ok: code == 200, code: code, message: msg);
  }

  Future<void> messageRead({required int id}) async {
    try {
      await _api.post(ApiEndpoints.messageRead, data: {'id': id});
    } catch (_) {
      // 樂觀呼叫即可，不需處理錯誤
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

    final code = raw['code'] is num
        ? (raw['code'] as num).toInt()
        : int.tryParse('${raw['code']}') ?? -1;
    final msg  = '${raw['message'] ?? ''}';
    if (code == 100 && msg.toLowerCase().contains('not found')) {
      return <Map<String, dynamic>>[];
    }
    if (code != 200) {
      throw Exception('拉取歷史失敗: ${msg.isEmpty ? 'unknown' : msg}');
    }

    // 1) 直接取 list
    final listRaw = (raw['data']?['list'] as List? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e));

    // 2) 只檢查 id（必要），不要用 request_id 篩
    final filtered = listRaw.where((m) => ('${m['id'] ?? ''}').trim().isNotEmpty);

    // 3) 去重改用 id（或乾脆不去重）
    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (final m in filtered) {
      final key = '${m['id']}'; // ✅ 唯一鍵
      if (seen.add(key)) deduped.add(m);
    }

    // （可選）log 用來核對
    debugPrint('[ChatAPI] history page=$page -> raw=${listRaw.length} '
        'filtered=${filtered.length} deduped=${deduped.length}');

    return deduped;
  }


  Future<List<CallRecordItem>> fetchUserCallRecordList({
    required int page,
    int? toUid,
  }) async {
    final resp = await _api.post(
      ApiEndpoints.userCallRecordList,
      data: {'page': page, if (toUid != null) 'to_uid': toUid},
    );
    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;
    final list = (raw?['data']?['list'] ?? []) as List;
    return list.map((e) => CallRecordItem.fromJson(Map<String, dynamic>.from(e))).toList();
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

  (int?, String?) _parseCodeMsg(dynamic raw) {
    final data = raw is String ? jsonDecode(raw) : raw;
    if (data is Map) {
      final c = (data['code'] is num)
          ? (data['code'] as num).toInt()
          : int.tryParse('${data['code']}');
      final m = '${data['message'] ?? data['msg'] ?? ''}';
      return (c, m);
    }
    return (null, null);
  }
}

class SendResult {
  final bool ok;           // 是否成功（code == 200）
  final int? code;         // 後端回傳 code
  final String? message;   // 後端 message（可選）
  const SendResult({required this.ok, this.code, this.message});
}
