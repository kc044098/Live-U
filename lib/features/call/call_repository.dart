import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../data/network/api_client.dart';
import '../../data/network/api_client_provider.dart';
import '../../data/network/api_endpoints.dart';

class CallRepository {
  final ApiClient _api;
  CallRepository(this._api);

  Future<Map<String, dynamic>> liveCall({
    required int flag, // 1=video, 2=audio
    required int toUid,
  }) async {
    final raw = await _api.post(
      ApiEndpoints.liveCall,
      data: {'flag': flag, 'to_uid': toUid},
    );
    final dyn = (raw is Response) ? raw.data : raw;
    return _toMap(dyn);
  }

  Future<Map<String, dynamic>> respondCall({
    required String channelName,
    String? callId,
    required bool accept, // true=1 接聽, false=2 拒絕/掛斷
  }) async {
    final raw = await _api.post(
      ApiEndpoints.liveCallAccept,
      data: {
        'channel_name': channelName,
        'callId': callId,
        'flag': accept ? 1 : 2,
      },
    );
    final dyn = (raw is Response) ? raw.data : raw;
    return _toMap(dyn);
  }

  Future<String> renewRtcToken({
    required String channelName,
  }) async {
    final raw = await _api.post(
      ApiEndpoints.renewRtcToken, // 你自己後端的路由
      data: {
        'channel_name': channelName,
      },
    );
    final map = _toMap(raw);
    // 後端回傳 key 你自己決定，這裡兼容幾種常見命名
    return (map['token'] ?? map['rtcToken'] ?? map['rtc_token'] ?? '').toString();
  }

  /// 把任意回傳(normal/Dio/JSON字串/其它)安全轉成 Map<String,dynamic>
  Map<String, dynamic> _toMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String && v.isNotEmpty) {
      try {
        final j = json.decode(v);
        if (j is Map<String, dynamic>) return j;
        if (j is Map) return Map<String, dynamic>.from(j);
        return {'data': j};
      } catch (_) {
        // 不是 JSON 就包起來
        return {'data': v};
      }
    }
    // 其他型別（list/bool/null...）一律包在 data 裡
    return {'data': v};
  }
}

/// Riverpod Provider
final callRepositoryProvider = Provider<CallRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return CallRepository(api);
});

final homeMuteAudioProvider = StateProvider<bool>((_) => false);