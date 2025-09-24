import 'package:djs_live_stream/features/auth/providers/auth_repository_provider.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/user_local_storage.dart';
import '../../data/models/user_model.dart';
import '../profile/profile_controller.dart';

import 'LoginMethod.dart';

class FacebookAuthService {
  Future<UserModel?> signInWithFacebook(WidgetRef ref) async {
      final result = await FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
      );
      if (result.status != LoginStatus.success) return null;

      final accessToken = result.accessToken!;
      final cred = FacebookAuthProvider.credential(accessToken.token);
      final userCred = await FirebaseAuth.instance.signInWithCredential(cred);
      final fb = userCred.user;
      if (fb == null) return null;

      final temp = UserModel(
        uid: fb.uid,
        displayName: fb.displayName ?? 'user',
        photoURL: [fb.photoURL ?? ''],
        extra: {'email': fb.email ?? ''},
        logins: [
          LoginMethod(
            provider: 'facebook',
            identifier: accessToken.userId,
            token: accessToken.token,
            isPrimary: true,
          ),
        ],
      );

      final authed = await ref.read(authRepositoryProvider).loginWithFacebook(temp);
      ref.read(userProfileProvider.notifier).setUser(authed);
      await UserLocalStorage.saveUser(authed);
      return authed;

  }

  Future<void> signOut() async {
    await FacebookAuth.instance.logOut();
    await FirebaseAuth.instance.signOut();
  }
}