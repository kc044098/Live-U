import 'dart:convert';

import 'package:dio/dio.dart';
import '../models/gift_item.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

class GiftRepository {
  GiftRepository(this._api);

  final ApiClient _api;

  List<GiftItemModel>? _cache;
  DateTime? _fetchedAt;

  bool get hasCache => _cache != null && _cache!.isNotEmpty;
  List<GiftItemModel> get cached => _cache ?? const [];

  bool isStale(Duration ttl) {
    if (_fetchedAt == null) return true;
    return DateTime.now().difference(_fetchedAt!) > ttl;
  }

  Future<List<GiftItemModel>> fetchGiftList({bool force = false}) async {
    if (!force && hasCache) {
      return _cache!;
    }

    Response resp = await _api.post(
      ApiEndpoints.giftList,
      data: const {}, // 無參數
    );
    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;

    if (raw is Map && (raw['code'] == 200)) {
      final data = (raw['data'] ?? {}) as Map;
      final list = (data['list'] as List? ?? [])
          .map((e) => GiftItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // 依後端可能回傳的 sort 排序（小到大）
      list.sort((a, b) => a.sort.compareTo(b.sort));

      _cache = list;
      _fetchedAt = DateTime.now();
      return list;
    }

    throw Exception('fetchGiftList failed: $resp');
  }
}
