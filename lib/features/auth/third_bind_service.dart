import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as fba;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

String _randomNonce([int length = 32]) {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final rand = Random.secure();
  return List.generate(length, (_) => charset[rand.nextInt(charset.length)]).join();
}
String _sha256ofString(String input) => sha256.convert(utf8.encode(input)).toString();

/// Google：拉起登入並回傳 bindThird 需要的 payload
Future<Map<String, String>?> getGoogleBindPayload() async {
  final google = GoogleSignIn(scopes: const ['email']);
  final acc = await google.signIn();
  if (acc == null) return null; // 使用者取消

  final auth = await acc.authentication;
  return {
    'flag'       : 'google',
    'o_auth_id'  : acc.id,                // 或 acc.email 也可
    'verify_code': auth.idToken ?? '',    // 後端可驗 Google ID Token
    'email'      : acc.email,
    'nick_name'  : acc.displayName ?? '',
    'avatar'     : acc.photoUrl ?? '',
  };
}

/// Facebook：拉起登入並回傳 payload
Future<Map<String, String>?> getFacebookBindPayload() async {
  final result = await fba.FacebookAuth.instance.login(
    permissions: const ['email', 'public_profile'],
    loginBehavior: defaultTargetPlatform == TargetPlatform.iOS
        ? fba.LoginBehavior.webOnly
        : fba.LoginBehavior.nativeWithFallback,
  );
  if (result.status != fba.LoginStatus.success || result.accessToken == null) {
    return null; // 取消或失敗
  }

  final token  = result.accessToken!.token;
  final userId = result.accessToken!.userId;

  // 取使用者基本資料（可能拿不到 email，視權限與帳號設定）
  final me = await fba.FacebookAuth.instance.getUserData(
    fields: 'id,name,email,picture.width(400)',
  );
  final email = (me['email'] ?? '').toString();
  final name  = (me['name']  ?? '').toString();
  final avatar = ((me['picture']?['data']?['url']) ?? '').toString();

  return {
    'flag'       : 'facebook',
    'o_auth_id'  : userId,      // 綁定用 FB userId
    'verify_code': token,       // 後端可驗 FB access token
    'email'      : email,
    'nick_name'  : name,
    'avatar'     : avatar,
  };
}

/// Apple：使用 SignInWithApple 直接拿 identityToken
Future<Map<String, String>?> getAppleBindPayload() async {
  final rawNonce = _randomNonce();
  final hashedNonce = _sha256ofString(rawNonce);

  final cred = await SignInWithApple.getAppleIDCredential(
    scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    nonce: hashedNonce,
  );

  // 組暱稱
  final fn = cred.givenName?.trim() ?? '';
  final ln = cred.familyName?.trim() ?? '';
  final nick = ([fn, ln]..removeWhere((e) => e.isEmpty)).join(' ').trim();

  return {
    'flag'       : 'apple',
    'o_auth_id'  : cred.userIdentifier ?? '',   // Apple 的 sub
    'verify_code': cred.identityToken ?? '',    // Apple identity token (JWT)
    'email'      : cred.email ?? '',
    'nick_name'  : nick.isNotEmpty ? nick : 'Apple User',
    'avatar'     : '',                          // Apple 不提供頭像
  };
}
