import 'dart:developer' as dev;
import 'dart:io';

import 'package:djs_live_stream/features/auth/providers/auth_repository_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as fba
    show FacebookAuth, LoginBehavior, LoginResult, LoginStatus, AccessToken, ClassicToken;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_handler.dart';
import '../../core/user_local_storage.dart';
import '../../data/models/user_model.dart';
import '../profile/profile_controller.dart';

import 'LoginMethod.dart';

class FacebookAuthService {
  Future<UserModel?> signInWithFacebook(WidgetRef ref) async {
    try {
      // iOS 強制 webOnly（避免 Limited Login），Android 保持原生
      final fba.LoginResult result = await fba.FacebookAuth.instance.login(
        permissions: const ['email', 'public_profile'],
        loginBehavior: Platform.isIOS
            ? fba.LoginBehavior.webOnly
            : fba.LoginBehavior.nativeWithFallback,
      );

      if (result.status != fba.LoginStatus.success || result.accessToken == null) {
        debugPrint('[FB] login fail: status=${result.status} msg=${result.message}');
        return null;
      }

      // 5.x API：直接用 token / userId
      final token  = result.accessToken!.token;
      final userId = result.accessToken!.userId;

      // 檢查一下前綴，EAA=classic；eyJ=JWT(通常是 limited)
      debugPrint('[FB] token head=${token.substring(0, 3)}');

      return _finishFirebaseLogin(ref, token, userId);

    } on FirebaseAuthException catch (e, st) {
      debugPrint('[FB][FirebaseAuth] code=${e.code} msg=${e.message}\n$st');
      if (Platform.isIOS && e.code == 'invalid-credential') {
        // iOS 若遇 190，多半是 limited 或 Redirect URI 未設定，清 session 以免卡住
        await fba.FacebookAuth.instance.logOut();
      }
      AppErrorToast.show(e);
      return null;

    } catch (e, st) {
      debugPrint('[FB] unexpected: $e\n$st');
      AppErrorToast.show(e);
      return null;
    }
  }

  Future<UserModel?> _finishFirebaseLogin(
      WidgetRef ref,
      String accessToken,
      String userId,
      ) async {
    final cred = FacebookAuthProvider.credential(accessToken);
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
          identifier: userId,
          token: accessToken,
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
    await fba.FacebookAuth.instance.logOut();
    await FirebaseAuth.instance.signOut();
  }
}