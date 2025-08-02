import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_repository.dart';
import '../../../data/models/user_model.dart';

final userProfileProvider =
StateNotifierProvider<UserProfileController, UserModel?>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return UserProfileController(repository);
});

class UserProfileController extends StateNotifier<UserModel?> {
  final ProfileRepository _repository;

  UserProfileController(this._repository) : super(null) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _repository.loadUser();
    state = user;
  }

  void updateDisplayName(String newName) {
    if (state != null) {
      final updated = state!.copyWith(displayName: newName);
      state = updated;
      _repository.saveUser(updated);
    }
  }

  void updateExtraField(String key, dynamic value) {
    if (state != null) {
      final extra = Map<String, dynamic>.from(state!.extra ?? {});
      extra[key] = value;
      final updated = state!.copyWith(extra: extra);
      state = updated;
      _repository.saveUser(updated);
    }
  }

  void setUser(UserModel user) {
    state = user;
  }

  void logout() async {
    await _repository.clearUser();
    state = null;
  }

}