import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../data/network/api_client.dart';
import '../../data/network/api_client_provider.dart';
import '../../data/network/api_endpoints.dart';   // 你集中管理的 endpoints

class CallRepository {
  final ApiClient _api;
  CallRepository(this._api);

  /// 發起通話
  /// Req:  { "flag": 1(視訊)|2(語音), "to_uid": 123 }
  /// Resp: { "channel_name"/"channle_name", "from_uid", "to_uid", "token"(主叫), ... }
  Future<Map<String, dynamic>> liveCall({
    required int flag,
    required int toUid,
  }) async {
    final payload = {"flag": flag, "to_uid": toUid};
    final res = await _api.post(ApiEndpoints.liveCall, data: payload);

    final body = (res.data is Map) ? res.data as Map : const {};
    final rawData = (body['data'] ?? body);
    final data = Map<String, dynamic>.from(rawData as Map);

    // normalize keys
    data['channel_name'] =
        (data['channel_name'] ?? data['channle_name'] ?? data['channel_id'])?.toString();

    // ints
    for (final k in ['from_uid', 'to_uid', 'caller_uid', 'callee_uid', 'uid']) {
      final v = data[k];
      if (v is num) data[k] = v.toInt();
    }

    return data;
  }

  /// 回覆來電（接聽/拒絕）
  /// Req:  { "channel_name": "xxx", "flag": 1(接聽)|2(拒絕) }
  /// 接聽預期 Resp: { "channel_name", "token"(被叫), "callee_uid"(或 uid) ... }
  /// 拒絕可能只回 message 或空 data；這裡做彈性解析
  Future<void> respondCall({
    required String channelName,
    required bool accept, // true=接聽(flag=1) / false=拒絕(flag=2)
  }) async {
    await _api.post(
      ApiEndpoints.liveCallAccept,
      data: {'channel_name': channelName, 'flag': accept ? 1 : 2},
    );
  }
}

/// Riverpod Provider
final callRepositoryProvider = Provider<CallRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return CallRepository(api);
});
