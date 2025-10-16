import 'dart:convert';

import 'package:flutter/cupertino.dart';

import '../../core/error_handler.dart';
import '../../data/models/user_model.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_endpoints.dart';
import 'LoginMethod.dart';


class AuthRepository {
  final ApiClient _api;
  AuthRepository(this._api);

  Future<UserModel?> bindThird(Map<String, String> payload) async {
    debugPrint('[bindThird] payload : ${payload}');
    final resp = await _api.postOk(ApiEndpoints.bindThird, data: payload);
    debugPrint('[bindThird] resp : ${resp}');

    // 後端若回 User 就解析；若沒回 data 就回 null 讓上層自行拼本地狀態
    final data = (resp['data'] as Map?)?.cast<String, dynamic>();
    return (data != null) ? UserModel.fromJson(data) : null;
  }

  Future<void> bindEmail({required String email, required String code}) async {
    await _api.postOk(
      ApiEndpoints.emailBind,
      data: {'email': email, 'code': code},
    );
  }

  /// 發送信箱驗證碼
  Future<void> sendEmailCode(String email) async {
    try {
      await _api.postOk(ApiEndpoints.sendEmailCode, data: {'email': email});
    } on ApiException catch (e) {
      // 113: Email Format Error
      if (e.code == 113) {
        throw const EmailFormatException();
      }
      rethrow;
    }
  }

  /// 郵箱驗證碼登入
  Future<UserModel> loginWithEmailCode({
    required String account,
    required String code,
  }) async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.loginEmail,
        data: {'account': account, 'code': code},
      );
      final data = (map['data'] as Map).cast<String, dynamic>();
      return _parseUser(
        data,
        loginProvider: 'email',
        loginId: account,
        token: data['token']?.toString() ?? '',
      );
    } on ApiException catch (e) {
      // 112: Verification Code Error
      if (e.code == 112) {
        throw const VerificationCodeException();
      }
      // 110: Account Or Password Error（有些後端會沿用這個碼）
      if (e.code == 110) {
        throw const BadCredentialsException();
      }
      rethrow;
    }
  }

  /// 郵箱密碼登入
  Future<UserModel> loginWithAccountPassword({
    required String account,
    required String password,
  }) async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.loginAccount,
        data: {'account': account, 'pwd': password},
      );
      final data = (map['data'] as Map).cast<String, dynamic>();
      return _parseUser(
        data,
        loginProvider: 'email',
        loginId: account,
        token: data['token']?.toString() ?? '',
      );
    } on ApiException catch (e) {
      // 110: 帳號或密碼錯誤
      if (e.code == 110) {
        throw const BadCredentialsException();
      }
      rethrow;
    }
  }

  /// 註冊（你目前路由使用 loginEmail，我保持不動）
  Future<UserModel> registerAccount({
    required String email,
    required String code,
    required String password,
  }) async {
    final map = await _api.postOk(
      ApiEndpoints.loginEmail,
      data: {'account': email, 'code': code, 'pwd': password},
    );
    final data = (map['data'] as Map).cast<String, dynamic>();
    return _parseUser(
      data,
      loginProvider: 'account',
      loginId: email,
      token: data['token']?.toString() ?? '',
    );
  }

  /// 重置密碼
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _api.postOk(
      ApiEndpoints.resetPassword,
      data: {'code': code, 'email': email, 'pwd': newPassword},
    );
  }

  /// Google 登錄
  Future<UserModel> loginWithGoogle(UserModel googleUser) async {
    final primaryLogin = googleUser.primaryLogin;
    if (primaryLogin == null) throw ApiException(-1, '缺少主要登入方式');

    final payload = {
      "flag": primaryLogin.provider,        // "google"
      "verify_code": primaryLogin.token,    // Firebase ID token 或你的驗證碼
      "o_auth_id": primaryLogin.identifier, // google uid/email
      "nick_name": googleUser.displayName,
      "email": googleUser.extra?['email'] ?? primaryLogin.identifier,
      "avatar": googleUser.avatarUrl,
    };

    final map = await _api.postOk(ApiEndpoints.login, data: payload);
    final data = (map['data'] as Map).cast<String, dynamic>();
    return _parseUser(
      data,
      loginProvider: 'google',
      loginId: primaryLogin.identifier,
      token: data['token']?.toString() ?? '',
    );
  }

  /// Apple 登錄
  Future<UserModel> loginWithApple(UserModel appleUser) async {
    final primary = appleUser.primaryLogin;
    if (primary == null) throw ApiException(-1, '缺少主要登入方式');

    final payload = {
      "flag": primary.provider,        // "apple"
      "verify_code": primary.token,    // Firebase ID token
      "o_auth_id": primary.identifier, // email(若有) 或 userId
      "nick_name": appleUser.displayName,
      "email": appleUser.extra?['email'] ?? '',
      "avatar": appleUser.avatarUrl,
    };

    final map = await _api.postOk(ApiEndpoints.login, data: payload);
    final data = (map['data'] as Map).cast<String, dynamic>();
    return _parseUser(
      data,
      loginProvider: 'apple',
      loginId: primary.identifier,
      token: data['token']?.toString() ?? '',
    );
  }

  /// Facebook 登錄
  Future<UserModel> loginWithFacebook(UserModel fbUser) async {
    final primary = fbUser.primaryLogin;
    if (primary == null) throw ApiException(-1, '缺少主要登入方式');

    final payload = {
      "flag": primary.provider,        // "facebook"
      "verify_code": primary.token,    // FB access token 或 Firebase ID token
      "o_auth_id": primary.identifier, // Facebook userId
      "nick_name": fbUser.displayName,
      "email": fbUser.extra?['email'] ?? '',
      "avatar": fbUser.avatarUrl,
    };

    final map = await _api.postOk(ApiEndpoints.login, data: payload);
    final data = (map['data'] as Map).cast<String, dynamic>();
    return _parseUser(
      data,
      loginProvider: 'facebook',
      loginId: primary.identifier,
      token: data['token']?.toString() ?? '',
    );
  }

  // 通用解析
  UserModel _parseUser(
      Map<String, dynamic> data, {
        required String loginProvider,
        required String loginId,
        required String token,
      }) {
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

/// ====== 可辨識例外 ======

class BadCredentialsException implements Exception {
  const BadCredentialsException();
  @override
  String toString() => '帳號或密碼錯誤';
}

class EmailFormatException implements Exception {
  final String message;
  const EmailFormatException([this.message = '信箱格式錯誤']);
  @override
  String toString() => message;
}

class VerificationCodeException implements Exception {
  const VerificationCodeException();
  @override
  String toString() => '驗證碼錯誤';
}