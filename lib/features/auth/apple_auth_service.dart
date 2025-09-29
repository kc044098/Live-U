import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:djs_live_stream/features/auth/providers/auth_repository_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_handler.dart';
import '../../core/user_local_storage.dart';
import '../../data/models/user_model.dart';
import '../profile/profile_controller.dart';

import 'LoginMethod.dart';


class AppleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithAppleViaFirebase(WidgetRef ref) async {
    try {
      final provider = OAuthProvider('apple.com');
      provider.addScope('email');
      provider.addScope('name');

      final cred = await _auth.signInWithProvider(provider);
      final user = cred.user;

      if (user != null) {
        final idToken = await user.getIdToken();

        final model = UserModel(
          uid: user.uid,
          displayName: user.displayName ?? 'Apple 用戶',
          photoURL: user.photoURL != null ? [user.photoURL!] : [],
          logins: [
            LoginMethod(
              provider: 'apple',
              identifier: user.uid, // 或 user.email ?? user.uid
              isPrimary: true,
              token: idToken,       // 送 Firebase ID Token 給後端驗證
            ),
          ],
          extra: {'email': user.email},
        );

        // ★ 只針對「呼叫後端 API」加錯誤處理
        try {
          final authRepository = ref.read(authRepositoryProvider);
          final result = await authRepository.loginWithApple(model);
          await UserLocalStorage.saveUser(result);
          ref.read(userProfileProvider.notifier).setUser(result);
        } catch (e) {
          // 後端/API 失敗：統一吐司，並回傳 null 讓 UI 判定為失敗
          AppErrorToast.show(e);
          return null;
        }
      }
      return user;
    } catch (e) {
      // Apple/Firebase 本地流程（使用者取消、Apple頁面關閉…）不屬於 API，僅記錄
      debugPrint('Apple via Firebase failed: $e');
      return null;
    }
  }
}