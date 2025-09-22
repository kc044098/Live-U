import 'dart:convert';

import 'package:dio/dio.dart';
import '../models/gift_item.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

class GiftRepository {
  GiftRepository(this._api);
  final ApiClient _api;

  List<GiftItemModel>? _cacheAll;
  List<GiftItemModel>? _cacheQuick;
  List<GiftItemModel>? _cacheNormal;
  Map<int, GiftItemModel>? _byId;
  DateTime? _fetchedAt;

  bool get hasCache => (_cacheAll != null && _cacheAll!.isNotEmpty);
  List<GiftItemModel> get cached => _cacheAll ?? const [];
  List<GiftItemModel> get cachedQuick  => _cacheQuick  ?? const [];
  List<GiftItemModel> get cachedNormal => _cacheNormal ?? const [];
  GiftItemModel? getById(int id) => _byId?[id];

  bool isStale(Duration ttl) {
    if (_fetchedAt == null) return true;
    return DateTime.now().difference(_fetchedAt!) > ttl;
  }

  Future<List<GiftItemModel>> fetchGiftList({bool force = false}) async {
    if (!force && hasCache) return _cacheAll!;

    final resp = await _api.post(ApiEndpoints.giftList, data: {"page": 1});
    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;

    if (raw is Map && raw['code'] == 200) {
      final data = (raw['data'] ?? {}) as Map;
      final list = (data['list'] as List? ?? [])
          .map((e) => GiftItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      // 後端 sort 由小到大
      list.sort((a, b) => a.sort.compareTo(b.sort));

      // ➜ 同步建立多個視圖/索引
      _cacheAll    = list;
      _cacheQuick  = list.where((g) => g.isQuick == 1).toList(growable: false);
      _cacheNormal = list.where((g) => g.isQuick != 1).toList(growable: false);
      _byId        = { for (final g in list) g.id : g };
      _fetchedAt   = DateTime.now();

      return _cacheAll!;
    }

    throw Exception('fetchGiftList failed: $resp');
  }
}

