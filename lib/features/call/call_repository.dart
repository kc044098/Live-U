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
    // code != 200 會丟 ApiException（統一由上層 Toast）
    final map = await _api.postOk(
      ApiEndpoints.liveCall,
      data: {'flag': flag, 'to_uid': toUid},
    );
    // 盡量維持原回傳：回 data（若不是 map 也包成 map）
    return _toMap(map['data']);
  }

  Future<Map<String, dynamic>> respondCall({
    required String channelName,
    String? callId,
    required bool accept, // true=1 接聽, false=2 拒絕/掛斷
  }) async {
    // 拒接/掛斷 → 容忍 124/126 視為成功（冪等）
    final alsoOk = accept ? const <int>{} : const <int>{124, 126};

    final map = await _api.postOk(
      ApiEndpoints.liveCallAccept,
      data: {
        'channel_name': channelName,
        'callId': callId,
        'flag': accept ? 1 : 2,
      },
      alsoOkCodes: alsoOk,
    );
    return _toMap(map['data']);
  }

  Future<String> renewRtcToken({
    required String channelName,
  }) async {
    final map = await _api.postOk(
      ApiEndpoints.renewRtcToken,
      data: {'channel_name': channelName},
    );
    final data = _toMap(map['data']);
    // 兼容常見命名（data 裡沒有時，再看最外層）
    return (data['token'] ??
        data['rtcToken'] ??
        data['rtc_token'] ??
        map['token'] ??
        map['rtcToken'] ??
        map['rtc_token'] ??
        '')
        .toString();
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
        return {'data': v};
      }
    }
    return {'data': v};
  }
}

/// Riverpod Provider
final callRepositoryProvider = Provider<CallRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return CallRepository(api);
});

final homeMuteAudioProvider = StateProvider<bool>((_) => false);