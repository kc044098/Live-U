import 'dart:convert';

import '../../data/models/user_model.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_endpoints.dart';

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

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
      "avatar": googleUser.photoURL,
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
      photoURL: data['avatar'],
      isVip: data['is_vip'] ?? false,
      isBroadcaster: data['is_broadcaster'] ?? false,
      logins: updatedLogins,
    );
  }
}

