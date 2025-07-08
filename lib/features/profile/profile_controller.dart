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

  void updateAvatar(String photoUrl) {
    if (state != null) {
      final updated = state!.copyWith(photoURL: photoUrl);
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