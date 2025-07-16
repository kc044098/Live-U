// 儲存使用者帳戶登錄資料的share preference
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';

class UserLocalStorage {
  static const _keyUser = 'user';
  static const _keyServerToken = 'serverToken';

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_keyUser, userJson);
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
  }

  static Future<void> saveServerToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyServerToken, token);
  }

  static Future<String?> getServerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyServerToken);
  }
}
