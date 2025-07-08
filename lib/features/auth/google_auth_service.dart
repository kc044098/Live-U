import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// 舊版 GoogleSignIn 用 constructor 建立
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  /// 手動登入流程
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Google Sign-In failed: $e');
      return null;
    }
  }

  /// 登出
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}