import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../config/env.dart';
import '../../core/error_handler.dart';
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
      AppErrorToast.show(e);   // 統一轉中文訊息
      return null;             // 後端失敗 → 視為登入失敗
    }
  }

  Future<User?> signInWithGoogle(WidgetRef ref) async {
    final sw = Stopwatch()..start();
    void log(String m) => debugPrint('[GGL] $m');
    String _short(String? s, {int head = 8}) {
      if (s == null || s.isEmpty) return '-';
      return s.length <= head ? s : '${s.substring(0, head)}…';
    }
    try {
      log('start env=${Env.current} api=${Env.apiBase}');

      final acc = await _googleSignIn.signIn();
      if (acc == null) { log('cancelled'); return null; }
      log('account=${acc.email ?? acc.id}');

      final gAuth = await acc.authentication;
      log('tokens id=${_short(gAuth.idToken)} access=${_short(gAuth.accessToken)}');

      final cred = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      final uc = await _firebaseAuth.signInWithCredential(cred);
      final fu = uc.user;
      if (fu == null) { log('firebase user=null'); return null; }
      log('firebase uid=${fu.uid} email=${fu.email ?? "-"}');

      final idToken = await fu.getIdToken();
      log('firebase idToken=${_short(idToken)}');

      final tempModel = UserModel(
        uid: fu.uid,
        displayName: fu.displayName,
        photoURL: fu.photoURL != null ? [fu.photoURL!] : [],
        logins: [
          LoginMethod(
            provider: 'google',
            identifier: fu.email ?? fu.uid,
            isPrimary: true,
            token: idToken,
          ),
        ],
        extra: {'email': fu.email},
      );

      final authRepo = ref.read(authRepositoryProvider);
      final result = await authRepo.loginWithGoogle(tempModel);
      log('backend login ok');

      await UserLocalStorage.saveUser(result);
      ref.read(userProfileProvider.notifier).setUser(result);

      final userRepo = ref.read(userRepositoryProvider);
      final updated = await userRepo.getMemberInfo(result);
      log('fetch member ok');

      await UserLocalStorage.saveUser(updated);
      ref.read(userProfileProvider.notifier).setUser(updated);

      log('done ${sw.elapsedMilliseconds}ms');
      return fu;
    } on FirebaseAuthException catch (e, st) {
      log('firebase error code=${e.code} msg=${e.message}');
      debugPrint('$st');
      AppErrorToast.show(e);
      return null;
    } on PlatformException catch (e, st) {
      log('platform error code=${e.code} msg=${e.message}');
      debugPrint('$st');
      AppErrorToast.show(e);
      return null;
    } catch (e, st) {
      log('error $e');
      debugPrint('$st');
      AppErrorToast.show(e);
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    await UserLocalStorage.clear();
  }
}
