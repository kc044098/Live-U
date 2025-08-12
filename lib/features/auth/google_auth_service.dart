import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../mine/user_repository_provider.dart';
import './providers/auth_repository_provider.dart';
import '../../core/user_local_storage.dart';
import '../../data/models/user_model.dart';
import '../profile/profile_controller.dart';
import 'LoginMethod.dart';

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

        // 使用新 UserModel 結構
        final tempModel = UserModel(
          uid: user.uid,
          displayName: user.displayName,
          photoURL: user.photoURL != null ? [user.photoURL!] : [],
          logins: [
            LoginMethod(
              provider: 'google',
              identifier: user.email ?? user.uid,
              isPrimary: true,
              token: idToken,
            ),
          ],
          extra: {
            'email': user.email,
          },
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
          displayName: user.displayName,
          photoURL: user.photoURL != null ? [user.photoURL!] : [],
          logins: [
            LoginMethod(
              provider: 'google',
              identifier: user.email ?? user.uid,
              isPrimary: true,
              token: idToken,
            ),
          ],
          extra: {
            'email': user.email,
          },
        );

        print('Firebase idToken: $idToken');
        print('user.uid: ${user.uid}');
        print('user.email: ${user.email}');
        print('user.displayName: ${user.displayName}');
        print('user.photoURL: ${user.photoURL}');

        final authRepository = ref.read(authRepositoryProvider);
        final resultModel = await authRepository.loginWithGoogle(tempModel);

        // **立即更新本地與 provider → 確保攔截器用的是最新 token**
        await UserLocalStorage.saveUser(resultModel);
        ref.read(userProfileProvider.notifier).setUser(resultModel);

        // 再去獲取完整會員資料
        final userRepo = ref.read(userRepositoryProvider);
        final updatedUser = await userRepo.getMemberInfo(resultModel);

        // 更新一次最終資料
        await UserLocalStorage.saveUser(updatedUser);
        ref.read(userProfileProvider.notifier).setUser(updatedUser);
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