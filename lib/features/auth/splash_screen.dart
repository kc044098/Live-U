import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId: '1028511300374-i1ml51f8oorm3o1fgfs9t6fos2vudmt2.apps.googleusercontent.com',
  );

  Future<User?> trySilentSignIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print('Silent sign-in failed: $e');
      return null;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

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

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}
