import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileRepository {
  // 暫時存在記憶體，未來可改為 SharedPreferences 或 API
  UserProfile? _cache;

  UserProfile getProfile() {
    return _cache ??
        UserProfile(userId: '1', name: 'Guest', avatarUrl: '');
  }

  void saveProfile(UserProfile profile) {
    _cache = profile;
    // TODO: 可擴充為 local 儲存或 API 同步
  }
}