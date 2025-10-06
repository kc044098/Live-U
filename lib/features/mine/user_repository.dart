import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../../core/error_handler.dart';
import '../../data/models/user_model.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_endpoints.dart';
import 'model/fan_user.dart';
import 'model/focus_user.dart';
import 'model/invite_user_item.dart';
import 'model/reward_item.dart';
import 'model/vip_plan.dart';

const kNoDataCodes = {100, 404};
class UserRepository {
  final ApiClient _api;
  UserRepository(this._api);

  /// 回傳 true 表示修改成功；false 表示失敗
  Future<bool> modifyPassword({
    required String oldPwd,
    required String newPwd,
  }) async {
    try {
      await _api.postOk(
        ApiEndpoints.modifyPassword,
        data: {"old_pwd": oldPwd, "new_pwd": newPwd},
      );
      return true;
    } catch (e) {
      AppErrorToast.show(e);
      return false;
    }
  }

  /// 獲取個人資訊（會更新當前使用者）
  Future<UserModel> getMemberInfo(UserModel currentUser) async {
    try {
      final map = await _api.postOk(ApiEndpoints.memberInfo, data: {});
      final data = toMap(map['data']);

      return currentUser.copyWith(
        displayName: (data['nick_name'] as String?)?.isNotEmpty == true
            ? data['nick_name']
            : currentUser.displayName,
        photoURL: (data['avatar'] is List && (data['avatar'] as List).isNotEmpty)
            ? (data['avatar'] as List).map((e) => e.toString()).toList()
            : currentUser.photoURL,
        isVip: (data['vip'] ?? (currentUser.isVip ? 1 : 0)) == 1,
        isBroadcaster: (data['flag'] ?? (currentUser.isBroadcaster ? 2 : 1)) == 2,
        account: data['account'] ?? currentUser.account,
        apple: data['apple'] ?? currentUser.apple,
        facebook: data['facebook'] ?? currentUser.facebook,
        flag: data['flag'] ?? currentUser.flag,
        gid: data['gid'] ?? currentUser.gid,
        google: data['google'] ?? currentUser.google,
        inviteCode: data['invite_code'] ?? currentUser.inviteCode,
        isTest: data['is_test'] ?? currentUser.isTest,
        loginIp: data['login_ip'] ?? currentUser.loginIp,
        oAuthId: data['o_auth_id'] ?? currentUser.oAuthId,
        pDirector: (data['p_director'] ?? currentUser.pDirector)?.toString(),
        pStaff: (data['p_staff'] ?? currentUser.pStaff)?.toString(),
        pSupervisor: (data['p_supervisor'] ?? currentUser.pSupervisor)?.toString(),
        regIp: data['reg_ip'] ?? currentUser.regIp,
        sex: data['sex'] ?? currentUser.sex,
        status: data['status'] ?? currentUser.status,
        tags: (data['tags'] as List?)?.map((e) => e.toString()).toList() ?? currentUser.tags,
        email: data['email'] ?? currentUser.email,
        password: data['pwd'] ?? currentUser.password,
        createAt: data['create_at'] ?? currentUser.createAt,
        loginTime: data['update_at'] ?? currentUser.loginTime,
        fans: data['fans'] ?? currentUser.fans,
        isLike: data['is_like'] ?? currentUser.isLike,
        extra: {...?currentUser.extra, ...(data['detail'] ?? {})},
      );
    } catch (e) {
      AppErrorToast.show(e);
      rethrow; // 若上層需要阻擋流程，可以選擇 rethrow；或返回 currentUser 視你的 UI 邏輯決定
    }
  }

  /// 查詢其他用戶資訊（不會改動本地登入者狀態）
  Future<UserModel> getMemberInfoById(int id) async {
    int? _intOf(dynamic v) => v is num ? v.toInt() : (v == null ? null : int.tryParse(v.toString()));
    try {
      final map = await _api.postOk(ApiEndpoints.memberInfo, data: {"id": id});
      final data = toMap(map['data']);

      return UserModel(
        uid: data['id']?.toString() ?? '',
        displayName: (data['nick_name'] ?? '').toString(),
        email: (data['email'] ?? '').toString(),
        photoURL: (data['avatar'] is List)
            ? (data['avatar'] as List).map((e) => e.toString()).toList()
            : [],
        isVip: (data['vip'] ?? 0) == 1,
        isBroadcaster: (data['flag'] ?? 1) == 2,
        sex: data['sex'],
        tags: (data['tags'] is List)
            ? (data['tags'] as List).map((e) => e.toString()).toList()
            : [],
        extra: (data['detail'] as Map?)?.cast<String, dynamic>() ?? const {},
        fans: data['fans'] ?? 0,
        isLike: data['is_like'] ?? 0,
        status: data['status'] ?? 0,
        videoPrice: _intOf(data['video_price']),
        voicePrice: _intOf(data['voice_price']),
      );
    } catch (e) {
      AppErrorToast.show(e);
      rethrow;
    }
  }


  // 🔁 更新個人資訊
  Future<bool> updateMemberInfo(Map<String, dynamic> updateData) async {
    final response = await _api.post(ApiEndpoints.memberInfoUpdate, data: updateData);
    final raw = response.data is String ? jsonDecode(response.data) : response.data;

    if (raw is! Map || raw['code'] != 200) {
      debugPrint('更新失敗: $raw');
      final s = AppErrorToast.resolveT(null);
      throw Exception(s.updateFailedCheckNetwork);
    }

    return true;
  }

  /// 取得 VIP 方案列表
  Future<List<VipPlan>> fetchVipPlans() async {
    try {
      final map = await _api.postOk(ApiEndpoints.memberVipList, data: {});
      final data = toMap(map['data']);
      final listJson = toList(data['list']);
      final plans = listJson
          .map((e) => VipPlan.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      plans.sort((a, b) {
        final s = a.sort.compareTo(b.sort);
        return s != 0 ? s : a.month.compareTo(b.month);
      });
      return plans;
    } catch (e) {
      AppErrorToast.show(e);
      rethrow;
    }
  }

  /// 購買 VIP（失敗會丟 ApiException 並已 Toast）
  Future<void> buyVip({required int id}) async {
    try {
      await _api.postOk(ApiEndpoints.buyVip, data: {"id": id});
    } catch (e) {
      AppErrorToast.show(e);
      rethrow;
    }
  }

  /// 特例：你的某些列表把 code==100 當「沒有更多」（不視為錯誤）
  Future<InviteUserPage> fetchInviteList({int page = 1}) async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.inviteList,
        data: {'page': page},
        alsoOkCodes: {100}, // 👈 讓 100 不丟例外
      );

      // code==100 → 代表「沒有更多」，通常 data 可能為空
      if (map['code'] == 100) {
        return InviteUserPage(list: const [], count: 0);
      }

      final data = toMap(map['data']);
      final listJson = toList(data['list']);
      final list = listJson
          .map((e) => InviteUserItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      final countRaw = data['count'];
      final count = countRaw is int ? countRaw : int.tryParse('$countRaw') ?? 0;

      return InviteUserPage(list: list, count: count);
    } catch (e) {
      AppErrorToast.show(e);
      // 失敗時回傳空頁以避免 UI 崩潰（依你 UI 邏輯調整）
      return InviteUserPage(list: [], count: 0);
    }
  }

  // 獲取標籤列表（改：postOk + 統一錯誤）
  Future<List<String>> fetchAllTags() async {
    int page = 1;
    final List<String> allTags = [];
    try {
      while (true) {
        final map = await _api.postOk(
          ApiEndpoints.memberTagList,
          data: {'page': page},
          alsoOkCodes: kNoDataCodes,
        );

        // 沒資料：直接回傳空
        if (kNoDataCodes.contains(map['code'])) {
          return allTags.reversed.toList();
        }

        final data = toMap(map['data']);
        if (data == null) return allTags.reversed.toList();

        final list = data['list'];
        final totalCount = data['count'];
        if (list is! List || list.isEmpty) break;

        allTags.addAll(list.map((e) => (e['title'] ?? '').toString()));

        final tc = (totalCount is int) ? totalCount : int.tryParse('$totalCount') ?? 0;
        if (tc > 0 && allTags.length >= tc) break;

        page++;
      }
      return allTags.reversed.toList();
    } catch (e) {
      AppErrorToast.show(e);
      rethrow;
    }
  }

  // 點擊喜歡（改：postOk + 統一錯誤）
  Future<bool> memberFocus({required String targetUid}) async {
    try {
      await _api.postOk(
        ApiEndpoints.memberFocus,
        data: {'id': int.tryParse(targetUid)},
      );
      return true;
    } catch (e) {
      AppErrorToast.show(e);
      return false;
    }
  }

  // 獲取粉絲列表（改：postOk + 統一錯誤）
  Future<MemberFansPage> fetchMemberFans({int page = 1}) async {
    int? _asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

    try {
      final map = await _api.postOk(
        ApiEndpoints.memberFans,
        data: {'page': page},
        alsoOkCodes: kNoDataCodes,
      );

      // 100、204…等「沒有資料」直接回空頁
      if (kNoDataCodes.contains(map['code'])) {
        return MemberFansPage(list: const [], count: 0);
      }

      final data = toMap(map['data']);
      final listJson = toList(data['list']);

      // ✅ 逐項保護轉型
      final list = listJson
          .whereType<Map>()
          .map((e) => MemberFanUser.fromJson(e.cast<String, dynamic>()))
          .toList();

      // ✅ count 取不到就用 list.length 當保底
      final count = _asInt(data['count']) ?? list.length;

      return MemberFansPage(list: list, count: count);
    } catch (e) {
      AppErrorToast.show(e);
      rethrow;
    }
  }

  // 獲取關注列表（改：postOk + 統一錯誤）
  Future<MemberFocusPage> fetchMemberFocusList({int page = 1}) async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.memberFocusList,
        data: {'page': page},
        alsoOkCodes: kNoDataCodes,
      );

      if (kNoDataCodes.contains(map['code'])) {
        return MemberFocusPage(list: [], count: 0);
      }

      final data = toMap(map['data']);
      final listJson = (data['list'] as List?) ?? const [];
      final list = listJson
          .map((e) => MemberFocusUser.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      final countRaw = data['count'];
      final count = countRaw is int ? countRaw : int.tryParse('$countRaw') ?? 0;

      return MemberFocusPage(list: list, count: count);
    } catch (e) {
      AppErrorToast.show(e);
      rethrow;
    }
  }

// 主播通話價格設置（改：postOk + 統一錯誤）
  Future<bool> setPrice({required bool isVideo, required int price}) async {
    try {
      final data = {
        'flag': 1,
        'name': isVideo ? 'video_price' : 'voice_price',
        'title': isVideo ? '视频价格' : '语音价格',
        'values': price.toString(),
      };
      await _api.postOk(ApiEndpoints.configSet, data: data);
      return true;
    } catch (e) {
      AppErrorToast.show(e);
      return false;
    }
  }

  /// 讀取價格配置：video_price / voice_price（改：postOk + 統一錯誤）
  /// 回傳 (video, voice)；若沒取到對應值則為 null
  Future<(int? video, int? voice)> readCallPrices() async {
    int? _asInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }
    try {
      final map = await _api.postOk(
        ApiEndpoints.config,
        data: {"values": ["video_price", "voice_price"]},
        alsoOkCodes: kNoDataCodes,
      );

      if (kNoDataCodes.contains(map['code'])) {
        return (null, null);
      }

      int? video;
      int? voice;

      final data = toMap(map['data']);
      final list = toList(data['list']);
      if (list != null) {
        for (final it in list) {
          if (it is Map) {
            final name = it['name']?.toString();
            final v = _asInt(it['values']);
            if (name == 'video_price') video = v;
            if (name == 'voice_price') voice = v;
          }
        }
      }
      return (video, voice);
    } catch (e) {
      AppErrorToast.show(e);
      return (null, null);
    }
  }

  /// 讀取主播通話價格（改：postOk + 統一錯誤）
  /// 回傳：{'video_price': 777, 'voice_price': 666}
  Future<Map<String, int>> fetchCallPrices() async {
    int? _asInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '');
    try {
      final map = await _api.postOk(
        ApiEndpoints.config,
        data: {"values": ["video_price", "voice_price"]},
        alsoOkCodes: kNoDataCodes,
      );

      if (kNoDataCodes.contains(map['code'])) {
        return <String, int>{};
      }

      final list = (map['data']?['list'] as List?) ?? const [];
      final out = <String, int>{};
      for (final e in list) {
        final m = (e as Map).cast<String, dynamic>();
        final name = m['name']?.toString();
        final val = _asInt(m['values']);
        if (name != null && val != null) {
          out[name] = val;
        }
      }
      return out;
    } catch (e) {
      AppErrorToast.show(e);
      return <String, int>{};
    }
  }

// 點擊喜歡視頻（改：postOk + 統一錯誤）
  Future<void> likeVideo({required int id}) async {
    try {
      await _api.postOk(ApiEndpoints.videoLike, data: {'id': id});
    } catch (e) {
      AppErrorToast.show(e);
      rethrow;
    }
  }

  /// 設定免擾（保留寬鬆容錯，但也先嘗試 postOk + 統一錯誤）
  Future<bool> setDndById(int id) async {
    try {
      // 若後端已統一 {code:200} 會直接成功
      await _api.postOk(ApiEndpoints.dndSet, data: {"id": id});
      return true;
    } catch (e) {
      // 有些環節可能仍是空 body，則 fallback 走原本寬鬆判斷
      try {
        final res = await _api.post(ApiEndpoints.dndSet, data: {"id": id});
        final raw = res.data;
        if (raw == null) return true;
        final obj = raw is String ? jsonDecode(raw) : raw;
        if (obj is Map && obj['code'] is int) return obj['code'] == 200;
        return true;
      } catch (_) {
        AppErrorToast.show(e);
        return false;
      }
    }
  }

  /// 讀取後端的勿擾狀態（改：錯誤也 Toast）
  Future<int?> readDnd() async {
    int? _asInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    try {
      // 這支 API 可能不是標準格式，所以不使用 postOk
      final res = await _api.post(ApiEndpoints.dndRead, data: {});
      final raw = res.data is String ? jsonDecode(res.data) : res.data;

      if (raw == null) return null;
      if (raw is num || raw is String) return _asInt(raw);

      if (raw is Map) {
        final candidates = [raw['data'], raw['id'], raw['value'], raw['dnd']];
        for (final c in candidates) {
          final v = _asInt(c);
          if (v != null) return v;
        }
      }
      return null;
    } catch (e) {
      AppErrorToast.show(e);
      return null;
    }
  }

  // 上傳檔案至 S3（改：Step1 用 postOk + 統一錯誤）
  Future<String> uploadToS3Avatar(File file) async {
    try {
      final fileExtension = getFileExtension(file);
      final mimeType = lookupMimeType(file.path) ?? _guessMime(fileExtension);

      // Step 1: 取得預簽名 URL（統一錯誤）
      final map = await _api.postOk(ApiEndpoints.preUpload, data: {
        'file_type': fileExtension,
      });
      final data = toMap(map['data']);

      final uploadUrl = data['url'];
      final fileUrl = data['file_url'];

      // Step 2: 上傳至 S3
      final dio = Dio();
      final uploadRes = await dio.put(
        uploadUrl,
        data: await file.readAsBytes(),
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'x-amz-acl': 'public-read',
          },
        ),
      );
      if (uploadRes.statusCode != 200) {
        final s = AppErrorToast.resolveT(null);
        throw ApiException(-1, s.uploadFailedCheckNetwork);
      }
      return fileUrl;
    } catch (e) {
      AppErrorToast.show(e);
      rethrow;
    }
  }

// 取得邀請連結（改：postOk + 統一錯誤）
  Future<String> fetchInviteUrl() async {
    try {
      final map = await _api.postOk(ApiEndpoints.inviteUrl, data: {});
      final data = toMap(map['data']);
      final url = data['values']?.toString() ?? '';
      if (url.isEmpty) {
        final s = AppErrorToast.resolveT(null);
        throw ApiException(-1, s.inviteLinkEmpty);
      }
      return url;
    } catch (e) {
      AppErrorToast.show(e);
      rethrow;
    }
  }

  // 獎勵列表（改：postOk + alsoOkCodes: {100}）
  Future<RewardPage> fetchRewardList({int flag = 3, int page = 1}) async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.rewordList,
        data: {'flag': flag, 'page': page},
        alsoOkCodes: kNoDataCodes,
      );

      if (kNoDataCodes.contains(map['code'])) {
        return RewardPage(list: [], count: 0);
      }

      final data = toMap(map['data']);
      final listJson = toList(data['list']);
      final list = listJson
          .map((e) => RewardItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList();

      final countRaw = data['count'];
      final count = countRaw is int ? countRaw : int.tryParse('$countRaw') ?? 0;

      return RewardPage(list: list, count: count);
    } catch (e) {
      AppErrorToast.show(e);
      // 視需求：失敗也可回空頁避免 UI 中斷
      return RewardPage(list: [], count: 0);
    }
  }

  // 通用：上傳任何檔案到 S3（改：Step1 用 postOk + 統一錯誤）
  Future<String> uploadToS3({
    required File file,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final fileExtension = _getFileExtension(file);
      final mimeType = lookupMimeType(file.path) ?? _guessMime(fileExtension);

      // Step 1: 取預簽名 URL（統一錯誤）
      final map = await _api.postOk(ApiEndpoints.preUpload, data: {
        'file_type': fileExtension,
      });
      final data = toMap(map['data']);

      final uploadUrl = data['url'];
      final fileUrl = data['file_url'];

      // Step 2: PUT 到 S3（使用串流節省記憶體）
      final dio = Dio();
      final fileLen = await file.length();
      final stream = file.openRead();

      final res = await dio.put(
        uploadUrl,
        data: stream,
        options: Options(
          headers: {
            'Content-Type': mimeType,
            'Content-Length': fileLen.toString(),
            'x-amz-acl': 'public-read',
          },
        ),
        onSendProgress: onProgress,
        cancelToken: cancelToken,
      );

      if (res.statusCode != 200) {
        final s = AppErrorToast.resolveT(null);
        throw Exception(s.updateFailedCheckNetwork);
      }
      return fileUrl;
    } catch (e) {
      AppErrorToast.show(e);
      rethrow;
    }
  }

  String _getFileExtension(File file) {
    final ext = p.extension(file.path).toLowerCase();
    return ext.startsWith('.') ? ext.substring(1) : ext;
  }

  String _guessMime(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }

  Map<String, dynamic> toMap(Object? v) =>
      v is Map ? v.cast<String, dynamic>() : const {};
  List toList(Object? v) => v is List ? v : const [];
  int? toInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse('${v ?? ''}');

  String getFileExtension(File file) {
    final ext = p.extension(file.path).toLowerCase(); // 例如 .jpg
    return ext.startsWith('.') ? ext.substring(1) : ext;
  }

  Future<void> logout() async {
    await _api.post(ApiEndpoints.logout);
  }
}

extension FirstNonEmpty on List<String> {
  String firstNonEmptyOrEmpty() {
    for (final s in this) { if (s.isNotEmpty) return s; }
    return '';
  }
}
