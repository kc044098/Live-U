import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/user_local_storage.dart';
import '../../../data/models/user_model.dart';
import '../profile/profile_controller.dart';

class GoogleAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId: '你的 clientId',
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
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoURL: user.photoURL,
          idToken: idToken,
        );

        await UserLocalStorage.saveUser(userModel);
        ref.read(userProfileProvider.notifier).setUser(userModel); // ✅ 更新 provider
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
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoURL: user.photoURL,
          idToken: idToken,
        );

        await UserLocalStorage.saveUser(userModel);
        ref.read(userProfileProvider.notifier).setUser(userModel); // ✅ 更新 provider
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
