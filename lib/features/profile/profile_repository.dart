// 從 UserLocalStorage 取得與儲存 UserModel
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/user_local_storage.dart';
import '../../data/models/user_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileRepository {
  Future<UserModel?> loadUser() async {
    return await UserLocalStorage.getUser();
  }

  Future<void> saveUser(UserModel user) async {
    await UserLocalStorage.saveUser(user);
  }

  Future<void> clearUser() async {
    await UserLocalStorage.clear();
  }
}
