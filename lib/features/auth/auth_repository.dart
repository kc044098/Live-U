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
    final response = await _api.post(ApiEndpoints.sendEmailCode, data: {'email': email});
    final raw = response.data is String ? jsonDecode(response.data) : response.data;
    if (raw is! Map || raw['code'] != 200) {
      throw Exception('發送驗證碼失敗: ${raw['message'] ?? '未知錯誤'}');
    }
  }

  // 郵箱驗證碼登入
  Future<UserModel> loginWithEmailCode({required String account, required String code}) async {
    final response = await _api.post(ApiEndpoints.loginEmail, data: {'account': account, 'code': code});
    final raw = response.data is String ? jsonDecode(response.data) : response.data;
    if (raw is! Map || raw['code'] != 200 || raw['data'] == null) {
      throw Exception("回傳格式錯誤: $raw");
    }
    return _parseUser(
      raw['data'],
      loginProvider: 'email',
      loginId: account,
      token: raw['data']['token'] ?? '',
    );
  }

  // 郵箱密碼登入
  Future<UserModel> loginWithAccountPassword({required String account, required String password}) async {
    final response = await _api.post(ApiEndpoints.loginAccount, data: {'account': account, 'pwd': password});
    final raw = response.data is String ? jsonDecode(response.data) : response.data;
    if (raw is! Map || raw['code'] != 200 || raw['data'] == null) {
      throw Exception("回傳格式錯誤: $raw");
    }
    return _parseUser(
      raw['data'],
      loginProvider: 'email',
      loginId: account,
      token: raw['data']['token'] ?? '',
    );
  }

  // 註冊
  Future<UserModel> registerAccount({required String email, required String code, required String password}) async {
    final response = await _api.post(ApiEndpoints.loginEmail, data: {'account': email, 'code': code, 'pwd': password});
    final raw = response.data is String ? jsonDecode(response.data) : response.data;
    if (raw is! Map || raw['code'] != 200 || raw['data'] == null) {
      throw Exception("回傳格式錯誤: $raw");
    }
    return _parseUser(
      raw['data'],
      loginProvider: 'account',
      loginId: email,
      token: raw['data']['token'] ?? '',
    );
  }

  // 重置密碼
  Future<void> resetPassword({required String email, required String code, required String newPassword}) async {
    final response = await _api.post(ApiEndpoints.resetPassword, data: {'code': code, 'email': email, 'pwd': newPassword});
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
  }

  // Google 登錄
  Future<UserModel> loginWithGoogle(UserModel googleUser) async {
    final primaryLogin = googleUser.primaryLogin;
    if (primaryLogin == null) throw Exception("缺少主要登入方式");

    final payload = {
      "flag": primaryLogin.provider,
      "verify_code": primaryLogin.token,
      "o_auth_id": primaryLogin.identifier,
      "nick_name": googleUser.displayName,
      "email": googleUser.extra?['email'] ?? primaryLogin.identifier,
      "avatar": googleUser.avatarUrl,
    };

    final response = await _api.post(ApiEndpoints.login, data: payload);
    final raw = response.data is String ? jsonDecode(response.data) : response.data;
    if (raw is! Map || raw['code'] != 200 || raw['data'] == null) {
      throw Exception("後端回傳格式錯誤: $raw");
    }
    return _parseUser(
      raw['data'],
      loginProvider: 'google',
      loginId: primaryLogin.identifier,
      token: raw['data']['token'] ?? '',
    );
  }

  // 通用解析
  UserModel _parseUser(Map<String, dynamic> data, {required String loginProvider, required String loginId, required String token}) {
    // 添加 logins
    final logins = [
      LoginMethod(
        provider: loginProvider,
        identifier: loginId,
        token: token,
        isPrimary: true,
      ).toJson()
    ];
    final newData = {...data, 'logins': logins};
    return UserModel.fromJson(newData);
  }
}