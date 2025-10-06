import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import '../../core/error_handler.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_endpoints.dart';
import '../../globals.dart';
import '../../l10n/l10n.dart';
import 'chat_thread_item.dart';
import 'data_model/call_record_item.dart';

class ChatRepository {
  ChatRepository(this._api);
  final ApiClient _api;

  // --- helpers --------------------------------------------------------------

  String _i18nSendFailed() {
    try {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) return S.of(ctx).sendFailed;
    } catch (_) {}
    return '發送失敗'; // fallback（與現有行為一致）
  }

  SendResult _fail(Object e) {
    if (e is ApiException) {
      return SendResult(ok: false, code: e.code, message: e.message);
    }
    if (e is DioException) {
      final sc = e.response?.statusCode;
      if (sc == 404) {
        return SendResult(ok: false, code: 404, message: AppErrorCatalog.messageFor(404));
      }
      final msg = e.message?.trim();
      return SendResult(
        ok: false,
        code: sc ?? -1,
        message: (msg?.isNotEmpty == true) ? msg : _i18nSendFailed(),
      );
    }
    return  SendResult(ok: false, code: -1, message: _i18nSendFailed());
  }

  // --- send APIs: 統一不丟例外，回傳 SendResult -------------------------------

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
    try {
      final ok = await _api.postOk(ApiEndpoints.messageSend, data: payload);
      final code = (ok['code'] as num?)?.toInt() ?? -1;
      final msg  = '${ok['message'] ?? ok['msg'] ?? ''}';
      return SendResult(ok: code == 200, code: code, message: msg);
    } catch (e) {
      return _fail(e);
    }
  }

  Future<SendResult> sendVoice({
    required String uuid,
    required int toUid,
    required String voicePath,
    required String durationSec,
    String flag = 'chat_person',
  }) async {
    final payload = {
      "data": {"voice_path": voicePath, "duration": durationSec},
      "flag": flag,
      "to_uid": toUid,
      "uuid": uuid,
    };
    try {
      final ok = await _api.postOk(ApiEndpoints.messageSend, data: payload);
      final code = (ok['code'] as num?)?.toInt() ?? -1;
      final msg  = '${ok['message'] ?? ok['msg'] ?? ''}';
      return SendResult(ok: code == 200, code: code, message: msg);
    } catch (e) {
      return _fail(e);
    }
  }

  Future<SendResult> sendImage({
    required String uuid,
    required int toUid,
    required String imagePath, // S3 相對路徑
    int? width,
    int? height,
    String flag = 'chat_person',
  }) async {
    final payload = {
      "data": {"img_path": imagePath, if (width != null) "width": width.toString(), if (height != null) "height": height.toString()},
      "flag": flag,
      "to_uid": toUid,
      "uuid": uuid,
    };
    try {
      final ok = await _api.postOk(ApiEndpoints.messageSend, data: payload);
      final code = (ok['code'] as num?)?.toInt() ?? -1;
      final msg  = '${ok['message'] ?? ok['msg'] ?? ''}';
      return SendResult(ok: code == 200, code: code, message: msg);
    } catch (e) {
      return _fail(e);
    }
  }

  Future<void> messageRead({required int id}) async {
    try {
      await _api.post(ApiEndpoints.messageRead, data: {'id': id});
    } catch (_) {
      // 樂觀呼叫即可，不需處理錯誤
    }
  }

  Future<List<Map<String, dynamic>>> fetchMessageHistory({
    required int page,
    required int toUid,
  }) async {
    try {
      // body code=100/404 都視為正常（空）
      final ok = await _api.postOk(
        ApiEndpoints.messageHistory,
        data: {"page": page, "to_uid": toUid},
        alsoOkCodes: {100, 404},
      );

      final data = (ok['data'] is Map) ? Map<String, dynamic>.from(ok['data']) : const <String, dynamic>{};
      final listAny = data['list'];
      if (listAny is! List) return <Map<String, dynamic>>[];

      final listRaw = listAny
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e));

      // 只檢查必填 id；用 id 去重
      final filtered = listRaw.where((m) => ('${m['id'] ?? ''}').trim().isNotEmpty);
      final seen = <String>{};
      final deduped = <Map<String, dynamic>>[];
      for (final m in filtered) {
        final key = '${m['id']}';
        if (seen.add(key)) deduped.add(m);
      }

      debugPrint('[ChatAPI] history page=$page -> raw=${listAny.length} filtered=${filtered.length} deduped=${deduped.length}');
      return deduped;
    } on DioException catch (e) {
      // 真正的 HTTP 404 → 空
      if (e.response?.statusCode == 404) return <Map<String, dynamic>>[];
      rethrow;
    }
  }

  Future<List<CallRecordItem>> fetchUserCallRecordList({
    required int page,
    int? toUid,
  }) async {
    try {
      final ok = await _api.postOk(
        ApiEndpoints.userCallRecordList,
        data: {'page': page, if (toUid != null) 'to_uid': toUid},
        alsoOkCodes: {100, 404},
      );
      final data = (ok['data'] is Map) ? Map<String, dynamic>.from(ok['data']) : const <String, dynamic>{};
      final listAny = data['list'];
      if (listAny is! List) return <CallRecordItem>[];
      return listAny
          .whereType<Map>()
          .map((e) => CallRecordItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return <CallRecordItem>[];
      rethrow;
    }
  }

  Future<ChatThreadPage> fetchUserMessageList({int page = 1}) async {
    try {
      final ok = await _api.postOk(
        ApiEndpoints.userMessageList,
        data: {"page": page},
        alsoOkCodes: {100, 404},
      );

      final data = (ok['data'] is Map) ? Map<String, dynamic>.from(ok['data']) : const <String, dynamic>{};
      final listAny = data['list'];
      final countAny = data['count'];

      final list = (listAny is List)
          ? listAny
          .whereType<Map>()
          .map((e) => ChatThreadItem.fromJson(Map<String, dynamic>.from(e)))
          .toList()
          : <ChatThreadItem>[];

      final count = (countAny is num) ? countAny.toInt() : list.length;
      return ChatThreadPage(items: list, totalCount: count);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return ChatThreadPage(items: const [], totalCount: 0);
      }
      rethrow;
    }
  }

  Future<void> sendAck(String uuid) async {
    try {
      await _api.post(ApiEndpoints.messageSend, data: {'flag': 'reply', 'uuid': uuid});
    } catch (_) {
      // ACK 失敗可忽略
    }
  }

}

class SendResult {
  final bool ok;           // 是否成功（code == 200）
  final int? code;         // 後端回傳 code 或錯誤碼（含 404）
  final String? message;   // 後端 message（可選）
  const SendResult({required this.ok, this.code, this.message});
}
