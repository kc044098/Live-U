import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:djs_live_stream/features/auth/providers/auth_repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/error_handler.dart';
import '../../core/user_local_storage.dart';
import '../../data/models/user_model.dart';
import '../profile/profile_controller.dart';

import 'LoginMethod.dart';
import 'dart:io' show Platform;


class AppleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===== 工具（iOS nonce 用）=====
  String _randomNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  String _sha256of(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  String? _asString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    if (v is List<int>) return String.fromCharCodes(v);
    return v.toString();
  }

  /// 對外統一入口（UI 就呼叫這個）
  Future<User?> signInWithAppleViaFirebase(WidgetRef ref) async {
    return Platform.isAndroid
        ? _signInWithAppleAndroid(ref)
        : _signInWithAppleIOS(ref);
  }

  // ===== iOS：保留你原本的 nonce 流程 =====
  Future<User?> _signInWithAppleIOS(WidgetRef ref) async {
    try {
      final available = await SignInWithApple.isAvailable();
      if (!available) {
        throw Exception('請先在裝置登入 iCloud 並開啟雙重認證（2FA）。');
      }

      final rawNonce = _randomNonce();
      final nonce = _sha256of(rawNonce);

      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = _asString(apple.identityToken);
      final authCode = _asString(apple.authorizationCode);

      final credential = OAuthProvider('apple.com').credential(
        idToken: idToken,
        accessToken: authCode, // 可不帶；Firebase 主要用 idToken + rawNonce
        rawNonce: rawNonce,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) return null;

      final firebaseIdToken = await user.getIdToken();

      final model = UserModel(
        uid: user.uid,
        displayName: user.displayName ?? 'Apple 用戶',
        photoURL: user.photoURL != null ? [user.photoURL!] : [],
        logins: [
          LoginMethod(
            provider: 'apple',
            identifier: user.uid,
            isPrimary: true,
            token: firebaseIdToken,
          ),
        ],
        extra: {'email': user.email},
      );

      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.loginWithApple(model);
      await UserLocalStorage.saveUser(result);
      ref.read(userProfileProvider.notifier).setUser(result);
      return user;
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('[SIWA iOS] code=${e.code} msg=${e.message}');
      if (e.code == AuthorizationErrorCode.canceled) return null;
      AppErrorToast.show('Apple 授權失敗，請確認已登入 iCloud、開啟 2FA。');
      return null;
    } on FirebaseAuthException catch (e) {
      AppErrorToast.show(e.message ?? 'Firebase 登入失敗');
      return null;
    } catch (e) {
      debugPrint('[SIWA iOS] $e');
      return null;
    }
  }

  // ===== Android：走 Firebase signInWithProvider（簡潔穩定）=====
  Future<User?> _signInWithAppleAndroid(WidgetRef ref) async {
    void log(String m) => debugPrint('[SIWA Android] $m');
    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');

      final cred = await _auth.signInWithProvider(provider);
      final user = cred.user;
      if (user == null) {
        log('user=null');
        return null;
      }

      final idToken = await user.getIdToken();
      log('uid=${user.uid} email=${user.email ?? "-"}');

      final model = UserModel(
        uid: user.uid,
        displayName: user.displayName ?? 'Apple 用戶',
        photoURL: user.photoURL != null ? [user.photoURL!] : [],
        logins: [
          LoginMethod(
            provider: 'apple',
            identifier: user.uid, // 或 user.email ?? user.uid
            isPrimary: true,
            token: idToken,
          ),
        ],
        extra: {'email': user.email},
      );

      try {
        final authRepo = ref.read(authRepositoryProvider);
        final result = await authRepo.loginWithApple(model);
        await UserLocalStorage.saveUser(result);
        ref.read(userProfileProvider.notifier).setUser(result);
      } catch (e) {
        AppErrorToast.show(e);
        return null;
      }

      return user;
    } on FirebaseAuthException catch (e) {
      // 常見：web-context-canceled（使用者關閉授權頁）
      debugPrint('[SIWA Android][FAE] code=${e.code} msg=${e.message}');
      if (e.code == 'web-context-canceled' ||
          e.code == 'user-cancelled' ||
          e.code == 'popup-closed-by-user') {
        return null;
      }
      AppErrorToast.show(e.message ?? 'Apple 登入失敗');
      return null;
    } catch (e) {
      debugPrint('[SIWA Android] $e');
      return null;
    }
  }

  // 登出
  Future<void> signOut() async {
    await _auth.signOut();
    await UserLocalStorage.clear();
  }
}
