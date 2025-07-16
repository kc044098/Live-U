import 'dart:convert';

import '../../data/models/user_model.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_endpoints.dart';

class AuthRepository {
  final ApiClient _api;

  AuthRepository(this._api);

  Future<UserModel> loginWithGoogle(UserModel googleUser) async {
    final payload = {
      "flag": "google",
      "verify_code": googleUser.idToken,
      "o_auth_id": googleUser.uid,
      "nick_name": googleUser.displayName,
      "email": googleUser.email,
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

    return googleUser.copyWith(
      idToken: data['token'],
      uid: data['uid'].toString(),
      email: data['email'],
      displayName: data['nick_name'],
      photoURL: data['avatar'],
    );
  }
}
