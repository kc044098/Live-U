import 'dart:convert';

import '../../data/models/user_model.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_endpoints.dart';
import 'LoginMethod.dart';

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

  // 發送信箱驗證碼
  Future<void> sendEmailCode(String email) async {
    final response = await _api.post(
      ApiEndpoints.sendEmailCode,
      data: {'email': email},
    );
    dynamic raw = response.data;

    if (raw is String) {
      raw = jsonDecode(raw);
    }
    if (raw is Map<String, dynamic>) {
      final code = raw['code'];
      if (code == 200) {
        return; // 成功
      } else {
        throw Exception('發送驗證碼失敗: ${raw['message'] ?? '未知錯誤'}');
      }
    } else {
      throw Exception('無法解析返回格式: $raw');
    }
  }

  // 郵箱驗證碼登錄
  Future<UserModel> loginWithEmailCode({required String account, required String code}) async {
    final response = await _api.post(
      ApiEndpoints.loginEmail,
      data: {
        'account': account,
        'code': code,
      },
    );

    if (response.statusCode == 200) {
      dynamic raw = response.data;
      if (raw is String) {
        raw = jsonDecode(raw);
      }
      if (raw is! Map) {
        throw Exception("回傳格式錯誤: $raw");
      }

      // 根據你提供的返回結構解析
      final user = UserModel(
        uid: (raw['uid'] ?? 0).toString(),
        displayName: raw['nick_name'] ?? 'Guest',
        photoURL: (raw['avatar'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        isVip: (raw['vip'] ?? 0) == 1,
        isBroadcaster: (raw['flag'] ?? 0) == 1,
        logins: [
          LoginMethod(
            provider: 'email',
            identifier: raw['email'] ?? account,
            isPrimary: true,
            token: raw['token'] ?? '',
          ),
        ],
        extra: {
          'cdn_url': raw['cdn_url'],
          'sex': raw['sex'],
          'is_login': raw['is_login'],
        },
      );

      return user;
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  // 郵箱密碼登錄
  Future<UserModel> loginWithAccountPassword({required String account, required String password}) async {
    final response = await _api.post(
      ApiEndpoints.loginAccount,
      data: {
        'account': account,
        'pwd': password,
      },
    );

    if (response.statusCode == 200) {
      dynamic raw = response.data;
      if (raw is String) {
        raw = jsonDecode(raw);
      }
      if (raw is! Map) {
        throw Exception("回傳格式錯誤: $raw");
      }

      // 根據你提供的返回結構解析
      final user = UserModel(
        uid: (raw['uid'] ?? 0).toString(),
        displayName: raw['nick_name'] ?? 'Guest',
        photoURL: (raw['avatar'] as List? ?? [])
            .map((e) => e.toString())
            .toList(),
        isVip: (raw['vip'] ?? 0) == 1,
        isBroadcaster: (raw['flag'] ?? 0) == 1,
        logins: [
          LoginMethod(
            provider: 'email',
            identifier: raw['email'] ?? account,
            isPrimary: true,
            token: raw['token'] ?? '',
          ),
        ],
        extra: {
          'cdn_url': raw['cdn_url'],
          'sex': raw['sex'],
          'is_login': raw['is_login'],
        },
      );

      return user;
    } else {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  // 帳號註冊
  Future<UserModel> registerAccount({required String email, required String code, required String password}) async {
    final response = await _api.post(
      ApiEndpoints.loginEmail,
      data: {
        'account': email,
        'code': code,
        'pwd': password,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final raw = response.data;
    if (raw is! Map || !raw.containsKey('data')) {
      throw Exception('回傳格式錯誤: $raw');
    }

    final data = raw['data'];
    if (data is! Map) {
      throw Exception('data 格式錯誤: $data');
    }

    return UserModel(
      uid: (data['uid'] ?? '0').toString(),
      displayName: data['nick_name'] ?? 'Guest',
      photoURL: (data['avatar'] as List? ?? []).map((e) => e.toString()).toList(),
      isVip: (data['vip'] ?? 0) == 1,
      isBroadcaster: (data['flag'] ?? 0) == 1,
      logins: [
        LoginMethod(
          provider: 'account',
          identifier: email,
          token: data['token'] ?? '',
          isPrimary: true,
        ),
      ],
      extra: {
        'cdn_url': data['cdn_url'],
        'sex': data['sex'],
        'email': data['email'],
        'is_login': data['is_login'],
      },
    );
  }

  // 現在新增重置密碼
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _api.post(
      ApiEndpoints.resetPassword, // 需要在 ApiEndpoints 定義
      data: {
        'code': code,
        'email': email,
        'pwd': newPassword,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
  }

  // google自動登錄
  Future<UserModel> loginWithGoogle(UserModel googleUser) async {
    final primaryLogin = googleUser.primaryLogin;
    if (primaryLogin == null) {
      throw Exception("缺少主要登入方式");
    }

    final payload = {
      "flag": primaryLogin.provider, // google/apple...
      "verify_code": primaryLogin.token, // 改用 login.token
      "o_auth_id": primaryLogin.identifier,
      "nick_name": googleUser.displayName,
      "email": primaryLogin.identifier.contains('@') ? primaryLogin.identifier : null,
      "avatar": googleUser.photoURL[0],
    };

    final response = await _api.post(ApiEndpoints.login, data: payload);

    dynamic raw = response.data;
    if (raw is String) {
      raw = jsonDecode(raw);
    }
    if (raw is! Map || !raw.containsKey('data')) {
      throw Exception("後端回傳格式錯誤: $raw");
    }

    final data = raw['data'];

    // 更新主要登入方式的 token（後端返回的 token）
    final updatedLogins = googleUser.logins.map((login) {
      if (login.provider == primaryLogin.provider &&
          login.identifier == primaryLogin.identifier) {
        return login.copyWith(token: data['token']);
      }
      return login;
    }).toList();

    return googleUser.copyWith(
      uid: data['uid'].toString(),
      displayName: data['nick_name'],
      photoURL: (data['avatar'] as List? ?? []).map((e) => e.toString()).toList(),
      isVip: data['is_vip'] ?? false,
      isBroadcaster: data['is_broadcaster'] ?? false,
      logins: updatedLogins,
    );
  }

}

