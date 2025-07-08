import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_model.dart';
import 'profile_repository.dart';

final userProfileProvider =
StateNotifierProvider<UserProfileController, UserProfile>((ref) {
  final repository = ref.read(profileRepositoryProvider);
  return UserProfileController(repository);
});

class UserProfileController extends StateNotifier<UserProfile> {
  final ProfileRepository _repository;

  UserProfileController(this._repository)
      : super(UserProfile(userId: '1', name: 'Guest', avatarUrl: ''));

  void updateName(String newName) {
    state = state.copyWith(name: newName);
    _repository.saveProfile(state);
  }

  void updateAvatar(String newUrl) {
    state = state.copyWith(avatarUrl: newUrl);
    _repository.saveProfile(state);
  }
}