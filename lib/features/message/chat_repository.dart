// lib/data/repositories/chat_repository.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/network/api_client.dart';
import '../../data/network/api_client_provider.dart';
import '../../data/network/api_endpoints.dart';

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
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final api = ref.read(apiClientProvider); // 你現有的 ApiClient provider
  return ChatRepository(api);
});