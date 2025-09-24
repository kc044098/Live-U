import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../data/models/member_video_model.dart';
import '../../data/models/user_model.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_endpoints.dart';
import '../profile/profile_controller.dart';
import 'data_model/feed_item.dart';
import 'data_model/live_end_summary.dart';
import 'data_model/music_track.dart';

class VideoRepository {
  final ApiClient _api;
  final AppConfig _config;
  final Ref _ref;

  VideoRepository(this._api, this._config, this._ref);

  /// 取得自己的動態列表（照片/影片混合）
  /// 傳入 page 進行分頁抓取（遵照後端頁碼規則）
  Future<MemberVideoPage> fetchMemberVideos({required int page, int? uid}) async {
    final Response res = await _api.post(
      ApiEndpoints.videoList,
      data: {"page": page, "uid": uid},
    );

    // 後端回傳格式：
    // { code:200, data:{ list:[{...}], count:43 } }
    final data = res.data['data'] as Map<String, dynamic>? ?? {};
    final rawList = (data['list'] as List?) ?? [];

    // 以使用者的 cdnUrl 為主，無則退回 apiBaseUrl
    final cdnUrl = _ref.read(userProfileProvider)?.cdnUrl;
    final base = (cdnUrl != null && cdnUrl.isNotEmpty)
        ? cdnUrl
        : _config.apiBaseUrl;

    final list = rawList
        .map((e) => MemberVideoModel.fromJson(e as Map<String, dynamic>)
        .withAbsoluteUrls(base))
        .toList();

    final count = (data['count'] ?? list.length) as int;

    return MemberVideoPage(list: list, count: count);
  }


  /// 取得首頁推薦影片/圖片流（分頁）
  Future<List<FeedItem>> fetchRecommend({required int page}) async {
    final Response res = await _api.post(
      ApiEndpoints.videoRecommend,
      data: {"page": page},
    );

    final data = res.data['data'] as Map<String, dynamic>? ?? const {};
    final rawList = (data['list'] as List?) ?? const [];

    final cdnUrl = _ref.read(userProfileProvider)?.cdnUrl;
    final base = (cdnUrl != null && cdnUrl.isNotEmpty) ? cdnUrl : _config.apiBaseUrl;

    return rawList
        .map((e) => FeedItem.fromJson(e as Map<String, dynamic>, cdnBaseUrl: base))
        .toList();
  }

  /// 取得音樂清單（無參數）
  Future<List<MusicTrack>> fetchMusicList() async {
    final Response res = await _api.post(ApiEndpoints.musicList);

    final data = (res.data['data'] as Map<String, dynamic>?) ?? const {};
    final rawList = (data['list'] as List?) ?? const [];

    // 你要的人物頭像 emoji（會循環使用）
    const coverEmojis = ['🧓🏻', '🙋🏼‍♀️', '👩🏻‍💼', '🧑🏻‍🎤', '🧑🏽‍🦱', '🧒🏻', '🧑', '👩', '👨',
      '🧒', '👶', '🧓', '🧔', '🧑‍🦰', '🧑‍🦱', '🧑‍🦳', '🧑‍🦲', '🧑‍💼', '🧑‍💻', '🧑‍🎓', '🧑‍⚕️',];

    return rawList.asMap().entries.map((entry) {
      final i = entry.key;
      final m = entry.value as Map<String, dynamic>;
      return MusicTrack(
        id: (m['id'] ?? '').toString(),
        title: (m['title'] ?? '') as String,
        artist: '官方曲庫',
        duration: Duration(seconds: (m['duration'] ?? 0) as int),
        coverEmoji: coverEmojis[i % coverEmojis.length],
        path: (m['url'] ?? '') as String,
        // 這兩個先本地管理（收藏/用過），API若未提供就先 false
        isFavorited: false,
        usedBefore: false,
        recommended: ((m['is_recommend'] ?? 0) as int) == 1,
      );
    }).toList(growable: false);
  }

  Future<List<UserModel>> fetchRecommendedUsers({int page = 1}) async {
    final Response res = await _api.post(
      ApiEndpoints.userRecommend,
      data: {'page': page},
    );

    final list = (res.data['data']['list'] as List)
        .map((e) => UserModel.fromJson(e))
        .toList();
    return list;
  }

  Future<void> updateVideo({
    required int id,
    required String title,
    required int isTop,
  }) async {
    final data = {
      "id": id,
      "title": title,
      "is_top": isTop,
    };
    await _api.post(ApiEndpoints.videoUpdate, data: data);
  }

  Future<LiveEndSummary> fetchLiveEnd({required String channelName}) async {
    final resp = await _api.post(ApiEndpoints.liveEnd, data: {
      'channel_name': channelName,
    });
    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;

    // 允許 data 為空，用預設 0 值回傳
    if (raw is Map && raw['code'] == 200) {
      final data = (raw['data'] ?? const {}) as Map;
      return LiveEndSummary.fromJson(Map<String, dynamic>.from(data));
    }
    // 後備：全部 0
    return const LiveEndSummary();
  }
}

