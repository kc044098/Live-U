import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../core/error_handler.dart';
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

  String _langCode() {
    try {
      // Flutter 3 推薦從 platformDispatcher 取用
      return ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    } catch (_) {
      return 'en';
    }
  }

  String _tOfficialLibrary() {
    final lc = _langCode();
    // 目前只區分 zh / 其它語言（英文）；之後想擴可再細分 zh-Hant、zh-Hans
    return (lc == 'zh') ? '官方曲庫' : 'Official library';
  }

  bool _looksNoData(Object e) {
    // 盡量不依賴型別，但優先處理 ApiException
    String s = e.toString().toLowerCase();
    if (e is ApiException) {
      if (e.code == 404 || e.code == 100) return true;
      s = e.message.toLowerCase();
    } else if (e is DioException) {
      final sc = e.response?.statusCode ?? 0;
      if (sc == 404) return true;
      s = '${e.response?.data ?? e.message}'.toLowerCase();
    }
    return s.contains('暫無資料') || s.contains('no data');
  }

  /// 取得自己的動態列表（照片/影片混合）
  Future<MemberVideoPage> fetchMemberVideos({required int page, int? uid}) async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.videoList,
        data: {"page": page, "uid": uid},
        alsoOkCodes: const {404, 100}, // 視為「沒有資料」
      );

      final data = (map['data'] as Map?) ?? const {};
      final rawList = (data['list'] as List?) ?? const [];

      final cdnUrl = _ref.read(userProfileProvider)?.cdnUrl;
      final base = (cdnUrl != null && cdnUrl.isNotEmpty) ? cdnUrl : _config.apiBaseUrl;

      final list = rawList
          .map((e) => MemberVideoModel.fromJson(Map<String, dynamic>.from(e))
          .withAbsoluteUrls(base))
          .toList(growable: false);

      final cnt = data['count'];
      final count = (cnt is num) ? cnt.toInt() : int.tryParse('${cnt ?? ''}') ?? list.length;

      return MemberVideoPage(list: list, count: count);
    } catch (e) {
      if (_looksNoData(e)) {
        return MemberVideoPage(list: [], count: 0);
      }
      rethrow;
    }
  }

  /// 取得首頁推薦影片/圖片流（分頁）
  Future<List<FeedItem>> fetchRecommend({required int page}) async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.videoRecommend,
        data: {"page": page},
        alsoOkCodes: const {404, 100},
      );

      final data = (map['data'] as Map?) ?? const {};
      final rawList = (data['list'] as List?) ?? const [];

      final cdnUrl = _ref.read(userProfileProvider)?.cdnUrl;
      final base = (cdnUrl != null && cdnUrl.isNotEmpty) ? cdnUrl : _config.apiBaseUrl;

      return rawList
          .map((e) =>
          FeedItem.fromJson(Map<String, dynamic>.from(e), cdnBaseUrl: base))
          .toList(growable: false);
    } catch (e) {
      if (_looksNoData(e)) return const <FeedItem>[];
      rethrow;
    }
  }

  /// 取得音樂清單
  Future<List<MusicTrack>> fetchMusicList() async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.musicList,
        alsoOkCodes: const {404, 100},
      );

      final data = (map['data'] as Map?) ?? const {};
      final rawList = (data['list'] as List?) ?? const [];

      const coverEmojis = [
        '🧓🏻','🙋🏼‍♀️','👩🏻‍💼','🧑🏻‍🎤','🧑🏽‍🦱','🧒🏻','🧑','👩','👨',
        '🧒','👶','🧓','🧔','🧑‍🦰','🧑‍🦱','🧑‍🦳','🧑‍🦲','🧑‍💼','🧑‍💻','🧑‍🎓','🧑‍⚕️',
      ];
      final officialArtist = _tOfficialLibrary();
      return rawList.asMap().entries.map((entry) {
        final i = entry.key;
        final m = Map<String, dynamic>.from(entry.value as Map);
        return MusicTrack(
          id: (m['id'] ?? '').toString(),
          title: (m['title'] ?? '') as String,
          artist: (m['artist'] is String && (m['artist'] as String).isNotEmpty)
              ? m['artist'] as String
              : officialArtist,
          duration: Duration(seconds: (m['duration'] is num) ? (m['duration'] as num).toInt() : 0),
          coverEmoji: coverEmojis[i % coverEmojis.length],
          path: (m['url'] ?? '') as String,
          isFavorited: false,
          usedBefore: false,
          recommended: ((m['is_recommend'] ?? 0) as int) == 1,
        );
      }).toList(growable: false);
    } catch (e) {
      if (_looksNoData(e)) return const <MusicTrack>[];
      rethrow;
    }
  }

  Future<List<UserModel>> fetchRecommendedUsers({int page = 1}) async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.userRecommend,
        data: {'page': page},
        alsoOkCodes: const {404, 100},
      );

      final data = (map['data'] as Map?) ?? const {};
      final rawList = (data['list'] as List?) ?? const [];

      return rawList
          .map((e) => UserModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } catch (e) {
      if (_looksNoData(e)) return const <UserModel>[];
      rethrow;
    }
  }

  Future<void> updateVideo({
    required int id,
    required String title,
    required int isTop,
  }) async {
    await _api.postOk(
      ApiEndpoints.videoUpdate,
      data: {"id": id, "title": title, "is_top": isTop},
    );
  }

  Future<LiveEndSummary> fetchLiveEnd({required String channelName}) async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.liveEnd,
        data: {'channel_name': channelName},
        alsoOkCodes: const {404, 100},
      );

      final data = (map['data'] as Map?) ?? const {};
      return LiveEndSummary.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      if (_looksNoData(e)) return const LiveEndSummary(); // 全 0 兜底
      rethrow;
    }
  }
}
