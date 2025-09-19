import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../../data/models/user_model.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_endpoints.dart';
import 'model/fan_user.dart';
import 'model/focus_user.dart';
import 'model/vip_plan.dart';

class UserRepository {
  final ApiClient _api;
  UserRepository(this._api);

  /// 回傳 true 表示修改成功；false 表示失敗
  Future<bool> modifyPassword({
    required String oldPwd,
    required String newPwd,
  }) async {
    try {
      final Response res = await _api.post(
        ApiEndpoints.modifyPassword,
        data: {"old_pwd": oldPwd, "new_pwd": newPwd},
      );

      // 依你後端約定：code == 200 表示成功
      final data = res.data is Map ? res.data as Map : {};
      final code = data['code'];
      return code == 200;
    } catch (e) {
      // 這裡可加上日誌或錯誤上報
      return false;
    }
  }

  /// 獲取個人資訊（會更新當前使用者）
  Future<UserModel> getMemberInfo(UserModel currentUser) async {
    final response = await _api.post(ApiEndpoints.memberInfo, data: {});
    final raw = response.data is String ? jsonDecode(response.data) : response.data;

    if (raw is! Map || raw['code'] != 200 || raw['data'] == null) {
      debugPrint('資料格式錯誤: $raw');
      throw Exception("資料格式錯誤 ...");
    }
    final data = raw['data'];

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

      // detail → extra
      extra: {...?currentUser.extra, ...(data['detail'] ?? {})},
    );
  }

  /// 查詢其他用戶資訊（不會改動本地登入者狀態）
  /// 查詢其他用戶資訊（不會改動本地登入者狀態）
  Future<UserModel> getMemberInfoById(int id) async {
    int? _intOf(dynamic v) => v is num ? v.toInt() : (v == null ? null : int.tryParse(v.toString()));

    final resp = await _api.post(ApiEndpoints.memberInfo, data: {"id": id});
    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;

    if (raw is! Map || raw['code'] != 200 || raw['data'] == null) {
      debugPrint('資料格式錯誤: $raw');
      throw Exception("資料格式錯誤 ...");
    }
    final Map<String, dynamic> data = raw['data'];

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

      // 🔹 新增：價格解析（後端鍵：video_price / voice_price，可數字或字串）
      videoPrice: _intOf(data['video_price']),
      voicePrice: _intOf(data['voice_price']),
    );
  }


  // 🔁 更新個人資訊
  Future<bool> updateMemberInfo(Map<String, dynamic> updateData) async {
    final response = await _api.post(ApiEndpoints.memberInfoUpdate, data: updateData);
    final raw = response.data is String ? jsonDecode(response.data) : response.data;

    if (raw is! Map || raw['code'] != 200) {
      debugPrint('更新失敗: $raw');
      throw Exception("更新失敗 , 請確認網路連線");
    }

    return true;
  }

  // 獲取標籤列表
  Future<List<String>> fetchAllTags() async {
    int page = 1;
    final List<String> allTags = [];

    while (true) {
      final response = await _api.post(ApiEndpoints.memberTagList, data: {'page': page});
      final raw = response.data is String ? jsonDecode(response.data) : response.data;

      if (raw is! Map || raw['code'] != 200 || raw['data'] == null) {
        debugPrint('獲取標籤失敗: $raw');
        throw Exception("獲取標籤資料失敗 , 請檢查網路");
      }

      final data = raw['data'];
      final list = data['list'];
      final totalCount = data['count'];

      if (list is! List || list.isEmpty) break;

      allTags.addAll(list.map((e) => e['title'].toString()));
      if (allTags.length >= totalCount) break;

      page++;
    }

    return allTags.reversed.toList();
  }

  // 點擊喜歡
  Future<void> memberFocus({required String targetUid}) async {
    await _api.post(
      ApiEndpoints.memberFocus,
      data: {'id': int.tryParse(targetUid) },
    );
  }

  // 獲取粉絲列表
  Future<MemberFansPage> fetchMemberFans({int page = 1}) async {
    final resp = await _api.post(ApiEndpoints.memberFans, data: {'page': page});
    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;

    if (raw is! Map || raw['code'] != 200 || raw['data'] == null) {
      debugPrint('獲取誰喜歡我失敗: $raw');
      throw Exception("獲取誰喜歡我失敗 , 請檢查網路");
    }

    final data = (raw['data'] as Map).cast<String, dynamic>();
    final listJson = (data['list'] as List?) ?? const [];

    final list = listJson
        .map((e) => MemberFanUser.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final countRaw = data['count'];
    final count = countRaw is int ? countRaw : int.tryParse('$countRaw') ?? 0;

    return MemberFansPage(list: list, count: count);
  }

  // 獲取關注列表
  Future<MemberFocusPage> fetchMemberFocusList({int page = 1}) async {
    final resp = await _api.post(ApiEndpoints.memberFocusList, data: {'page': page});
    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;

    if (raw is! Map || raw['code'] != 200 || raw['data'] == null) {
      debugPrint('獲取我的關注列表失敗: $raw');
      throw Exception("獲取我的關注列表失敗 , 請檢查網路");
    }

    final data = (raw['data'] as Map).cast<String, dynamic>();
    final listJson = (data['list'] as List?) ?? const [];

    final list = listJson
        .map((e) => MemberFocusUser.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    final countRaw = data['count'];
    final count = countRaw is int ? countRaw : int.tryParse('$countRaw') ?? 0;

    return MemberFocusPage(list: list, count: count);
  }

  // 主播通話價格設置
  Future<void> setPrice({required bool isVideo, required int price}) async {
    final data = {
      'flag'  : 1,
      'name'  : isVideo ? 'video_price' : 'voice_price',
      'title' : isVideo ? '视频价格' : '语音价格',
      'values': price.toString(),
    };
    await _api.post(ApiEndpoints.configSet, data: data);
  }

  /// 讀取價格配置：video_price / voice_price
  /// 回傳 (video, voice)；若沒取到對應值則為 null
  Future<(int? video, int? voice)> readCallPrices() async {
    try {
      final res = await _api.post(
        ApiEndpoints.config,
        data: {
          "values": ["video_price", "voice_price"],
        },
      );
      final raw = res.data is String ? jsonDecode(res.data) : res.data;

      int? _asInt(dynamic v) {
        if (v == null) return null;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString());
      }

      int? video;
      int? voice;

      if (raw is Map && raw['code'] == 200) {
        final data = raw['data'] as Map?;
        final list = data?['list'] as List?;
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
      }

      return (video, voice);
    } catch (e) {
      debugPrint('[Price] readCallPrices error: $e');
      return (null, null);
    }
  }

  /// 讀取主播通話價格（video_price / voice_price）
  /// 回傳：{'video_price': 777, 'voice_price': 666}
  Future<Map<String, int>> fetchCallPrices() async {
    final resp = await _api.post(ApiEndpoints.config, data: {
      "values": ["video_price", "voice_price"]
    });
    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;

    if (raw is! Map || raw['code'] != 200) {
      debugPrint('讀取價格失敗: $raw');
      throw Exception('獲取價格失敗 , 請檢查網路連線');
    }

    final list = (raw['data']?['list'] as List?) ?? const [];
    int? _asInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '');

    final out = <String, int>{};
    for (final e in list) {
      final m = (e as Map).cast<String, dynamic>();
      final name = m['name']?.toString();
      final val  = _asInt(m['values']);
      if (name != null && val != null) {
        out[name] = val;
      }
    }
    return out;
  }

  /// 取得 VIP 方案列表（以 sort 升冪；若沒有 sort 就以 month 升冪）
  Future<List<VipPlan>> fetchVipPlans() async {
    final resp = await _api.post(ApiEndpoints.memberVipList, data: {});
    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;

    if (raw is! Map || raw['code'] != 200 || raw['data'] == null) {
      debugPrint('取得 VIP 禮包失敗: $raw');
      throw Exception("購買 VIP 禮包失敗");
    }

    final data = (raw['data'] as Map).cast<String, dynamic>();
    final listJson = (data['list'] as List?) ?? const [];
    final plans = listJson
        .map((e) => VipPlan.fromJson((e as Map).cast<String, dynamic>()))
        .toList();

    // sort → month
    plans.sort((a, b) {
      final s = a.sort.compareTo(b.sort);
      return s != 0 ? s : a.month.compareTo(b.month);
    });

    return plans;
  }

  Future<void> buyVip({required int id}) async {
    final resp = await _api.post(ApiEndpoints.buyVip, data: {"id": id});
    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;

    if (raw is! Map || raw['code'] != 200) {
      final msg = raw is Map ? (raw['message']?.toString() ?? '購買失敗') : '購買失敗';
      throw Exception(msg);
    }
  }

  // 點擊喜歡視頻
  Future<void> likeVideo({required int id}) async {
    await _api.post(ApiEndpoints.videoLike, data: {'id': id});
  }

  /// 設定免擾：id=0 關閉；1~6 對應 15m~24h。後端無回傳值也當成功。
  Future<bool> setDndById(int id) async {
    try {
      final res = await _api.post(ApiEndpoints.dndSet, data: {"id": id});
      final raw = res.data;

      // 可能完全沒 body；或有 {code:200}；兩者都視為成功
      if (raw == null) return true;
      final obj = raw is String ? jsonDecode(raw) : raw;
      if (obj is Map && obj['code'] is int) return obj['code'] == 200;
      return true;
    } catch (e) {
      debugPrint('[DND] setDndById error: $e');
      return false;
    }
  }

  /// 讀取後端的勿擾狀態，回傳 0~6（0=關閉）
  Future<int?> readDnd() async {
    try {
      final res = await _api.post(ApiEndpoints.dndRead, data: {});
      final raw = res.data is String ? jsonDecode(res.data) : res.data;

      // 常見幾種回傳型別都處理一下：純數字、字串、或包在 data/map 裡
      int? _asInt(dynamic v) {
        if (v == null) return null;
        if (v is num) return v.toInt();
        return int.tryParse(v.toString());
      }

      if (raw == null) return null;
      if (raw is num || raw is String) return _asInt(raw);

      if (raw is Map) {
        // 嘗試常見鍵位
        final candidates = [
          raw['data'],
          raw['id'],
          raw['value'],
          raw['dnd'],
        ];
        for (final c in candidates) {
          final v = _asInt(c);
          if (v != null) return v;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[DND] readDnd error: $e');
      return null;
    }
  }

  // 上傳檔案至 S3
  Future<String> uploadToS3Avatar(File file) async {
    final fileExtension = getFileExtension(file);
    final mimeType = lookupMimeType(file.path) ?? _guessMime(fileExtension);

    // Step 1: 取得預簽名 URL
    final response = await _api.post(ApiEndpoints.preUpload, data: {
      'file_type': fileExtension,
    });

    final raw =
        response.data is String ? jsonDecode(response.data) : response.data;
    if (raw is! Map || raw['code'] != 200 || raw['data'] == null) {
      debugPrint('取得預簽名 URL 失敗: $raw');
      throw Exception("上傳失敗");
    }

    final data = raw['data'];
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
      debugPrint('S3 資料上傳失敗: ${uploadRes.statusCode}');
      throw Exception('資料上傳失敗 , 請檢查網路');
    }

    return fileUrl;
  }

  // 通用：上傳任何檔案到 S3（支援進度、取消）
  Future<String> uploadToS3({
    required File file,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onProgress,
  }) async {
    final fileExtension = _getFileExtension(file);
    final mimeType = lookupMimeType(file.path) ?? _guessMime(fileExtension);

    // Step 1: 取預簽名 URL
    final response = await _api.post(ApiEndpoints.preUpload, data: {
      'file_type': fileExtension,
    });
    final raw = response.data is String ? jsonDecode(response.data) : response.data;
    if (raw is! Map || raw['code'] != 200 || raw['data'] == null) {
      debugPrint('取得預簽名 URL 失敗: $raw');
      throw Exception("上傳失敗");
    }
    final data = raw['data'];
    final uploadUrl = data['url'];
    final fileUrl   = data['file_url'];

    // Step 2: PUT 到 S3（使用串流節省記憶體）
    final dio = Dio();
    final fileLen = await file.length();
    final stream = file.openRead(); // Stream<List<int>>

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
      debugPrint('S3 上傳失敗: ${res.statusCode}');
      throw Exception('資料上傳失敗 , 請檢查網路');
    }
    return fileUrl;
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

  String getFileExtension(File file) {
    final ext = p.extension(file.path).toLowerCase(); // 例如 .jpg
    return ext.startsWith('.') ? ext.substring(1) : ext;
  }

  DateTime? _parseUntil(dynamic v) {
    if (v == null) return null;
    if (v is num) {
      final n = v.toInt();
      // 判斷是秒還是毫秒
      final ms = n < 1000000000000 ? n * 1000 : n;
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    if (v is String) {
      // ISO 或 數字字串
      final iso = DateTime.tryParse(v);
      if (iso != null) return iso;
      final asInt = int.tryParse(v);
      if (asInt != null) return _parseUntil(asInt);
    }
    return null;
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


