

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import './providers/auth_repository_provider.dart';
import '../../core/user_local_storage.dart';
import '../../data/models/user_model.dart';
import '../profile/profile_controller.dart';

class GoogleAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  Future<User?> trySilentSignIn(WidgetRef ref) async {
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final idToken = await user.getIdToken();
        final tempModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoURL: user.photoURL,
          idToken: idToken,
        );

        final authRepository = ref.read(authRepositoryProvider);
        final resultModel = await authRepository.loginWithGoogle(tempModel);
        print('🔥 準備送出資料給後端');
        print(tempModel.toJson());

        await UserLocalStorage.saveUser(resultModel);
        print('✅ 後端回傳成功: ${resultModel.toJson()}');

        ref.read(userProfileProvider.notifier).setUser(resultModel);
      }

      return user;
    } catch (e) {
      print('Silent sign-in failed: $e');
      return null;
    }
  }

  Future<User?> signInWithGoogle(WidgetRef ref) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final idToken = await user.getIdToken();
        final tempModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoURL: user.photoURL,
          idToken: idToken,
        );

        print('Firebase idToken: $idToken');
        print('user.uid: ${user.uid}');
        print('user.email: ${user.email}');
        print('user.displayName: ${user.displayName}');
        print('user.photoURL: ${user.photoURL}');

        final authRepository = ref.read(authRepositoryProvider);
        final resultModel = await authRepository.loginWithGoogle(tempModel);
        print('🔥 準備送出登錄資料給後端');
        print(tempModel.toJson());

        await UserLocalStorage.saveUser(resultModel);
        print('✅ 後端回傳登錄成功: ${resultModel.toJson()}');

        ref.read(userProfileProvider.notifier).setUser(resultModel);
      }

      return user;
    } catch (e) {
      print('Google Sign-In failed: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    await UserLocalStorage.clear();
  }
}
