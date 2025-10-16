import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart' as fba;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/error_handler.dart';
import '../../core/user_local_storage.dart';
import '../../data/models/user_model.dart';
import '../../l10n/l10n.dart';
import '../auth/LoginMethod.dart';
import '../auth/providers/auth_repository_provider.dart';
import '../profile/profile_controller.dart';
import 'add_email_account_page.dart';
import 'account_info_page.dart';

class AccountManagePage extends ConsumerStatefulWidget {
  const AccountManagePage({super.key});
  @override
  ConsumerState<AccountManagePage> createState() => _AccountManagePageState();
}

class _AccountManagePageState extends ConsumerState<AccountManagePage> {
  bool _isBinding = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final user = ref.watch(userProfileProvider);

    final googleStatus = _getBindStatus(context, user, 'google');
    final facebookStatus = _getBindStatus(context, user, 'facebook');
    final appleStatus = _getBindStatus(context, user, 'apple');

    final emailRaw = _getBindStatus(context, user, 'email');
    final emailBound = emailRaw != null;
    final displayEmail = emailBound ? _ellipsis15(emailRaw, max: 15) : s.statusToBind;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.accountManageTitle, style: const TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF8F8F8),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (user?.isBroadcaster ?? false) ...[
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: SvgPicture.asset('assets/icon_account.svg', width: 24, height: 24),
                    title: Text(s.accountLabel),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayEmail,
                          style: TextStyle(color: emailBound ? Colors.black54 : Colors.red, fontSize: 14),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AccountInfoPage(
                            avatarImage: user!.avatarImage,
                            modifyType: 'account',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 郵箱 + 提示
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 45,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(s.emailBindHint, style: const TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: SvgPicture.asset('assets/icon_email.svg', width: 24, height: 24),
                      title: Text(s.emailLabel),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayEmail,
                            style: TextStyle(color: emailBound ? Colors.black54 : Colors.red, fontSize: 14),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
                        ],
                      ),
                      onTap: () async {
                        final user = ref.read(userProfileProvider);
                        final hasEmail = user?.logins.any((l) => l.provider == 'email') ?? false;

                        if (!hasEmail) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddEmailAccountPage()),
                          );
                          if (result is String && result.isNotEmpty) {
                            _appendLoginLocal(
                              provider: 'email',
                              identifier: result,
                              token: '',
                              isPrimary: false,
                            );
                          }
                        } else {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AccountInfoPage(
                                avatarImage: user!.avatarImage,
                                modifyType: 'email',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              // ===== 第三方帳號 =====
              _buildAccountCard('assets/icon_facebook.svg', 'Facebook', status: facebookStatus, onTap: () => _onBindThird('facebook')),
              const SizedBox(height: 20),
              _buildAccountCard('assets/icon_google.svg', 'Google', status: googleStatus, onTap: () => _onBindThird('google')),
              const SizedBox(height: 20),
              _buildAccountCard('assets/icon_apple.svg', 'Apple', status: appleStatus, onTap: () => _onBindThird('apple')),
            ],
          ),

        ],
      ),
    );
  }

  // —— 綁定主流程 —— //
  Future<void> _onBindThird(String provider) async {
    final s = S.of(context);
    final lower = provider.toLowerCase();

    // 已綁定就不再拉起
    final current = ref.read(userProfileProvider);
    final already = current?.logins.any((e) => e.provider.toLowerCase() == lower) ?? false;

    setState(() => _isBinding = true);
    try {
      Map<String, String>? payload;

      switch (lower) {
        case 'google':
          payload = await _getGoogleBindPayload();
          break;
        case 'facebook':
          payload = await _getFacebookBindPayload();
          break;
        case 'apple':
          payload = await _getAppleBindPayload();
          break;
      }

      if (!mounted) return;
      if (payload == null) {
        Fluttertoast.showToast(msg: s.commonCancel);
        return;
      }

      // 呼叫後端綁定
      final repo = ref.read(authRepositoryProvider);
      final boundUser = await repo.bindThird(payload);

      if (boundUser != null) {
        // 後端直接回完整會員
        await UserLocalStorage.saveUser(boundUser);
        ref.read(userProfileProvider.notifier).setUser(boundUser);
      } else {
        // 後端只回成功 → 本地追加 login 記錄（顯示用）
        _appendLoginLocal(
          provider: payload['flag'] ?? lower,
          identifier: payload['email']?.isNotEmpty == true
              ? payload['email']!
              : (payload['o_auth_id'] ?? ''),
          token: payload['verify_code'] ?? '',
          isPrimary: false,
        );
      }

      Fluttertoast.showToast(msg: s.statusSuccess);
    } catch (e) {
      AppErrorToast.show(e);
    } finally {
      if (mounted) setState(() => _isBinding = false);
    }
  }

  Future<Map<String, String>?> _getGoogleBindPayload() async {
    final google = GoogleSignIn(scopes: const ['email']);
    final acc = await google.signIn();
    if (acc == null) return null;

    final auth = await acc.authentication;
    return {
      'flag'       : 'google',
      'o_auth_id'  : acc.id,                 // 也可用 acc.email
      'verify_code': auth.idToken ?? '',     // Google ID Token
      'email'      : acc.email,
      'nick_name'  : acc.displayName ?? '',
      'avatar'     : acc.photoUrl ?? '',
    };
  }

  Future<Map<String, String>?> _getFacebookBindPayload() async {
    final res = await fba.FacebookAuth.instance.login(
      permissions: const ['email', 'public_profile'],
      loginBehavior: Theme.of(context).platform == TargetPlatform.iOS
          ? fba.LoginBehavior.webOnly
          : fba.LoginBehavior.nativeWithFallback,
    );
    if (res.status != fba.LoginStatus.success || res.accessToken == null) return null;

    final token  = res.accessToken!.token;
    final userId = res.accessToken!.userId;

    final me = await fba.FacebookAuth.instance.getUserData(fields: 'id,name,email,picture.width(400)');
    return {
      'flag'       : 'facebook',
      'o_auth_id'  : userId,
      'verify_code': token,                        // FB access token
      'email'      : (me['email'] ?? '').toString(),
      'nick_name'  : (me['name']  ?? '').toString(),
      'avatar'     : ((me['picture']?['data']?['url']) ?? '').toString(),
    };
  }

  Future<Map<String, String>?> _getAppleBindPayload() async {
    final raw = _randomNonce();
    final hashed = _sha256ofString(raw);

    final cred = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: hashed,
    );

    final fn = cred.givenName?.trim() ?? '';
    final ln = cred.familyName?.trim() ?? '';
    final nick = ([fn, ln]..removeWhere((e) => e.isEmpty)).join(' ').trim();

    return {
      'flag'       : 'apple',
      'o_auth_id'  : cred.userIdentifier ?? '',
      'verify_code': cred.identityToken ?? '',
      'email'      : cred.email ?? '',
      'nick_name'  : nick.isNotEmpty ? nick : 'Apple User',
      'avatar'     : '',
    };
  }

  // —— 工具 —— //
  void _appendLoginLocal({
    required String provider,
    required String identifier,
    required String token,
    required bool isPrimary,
  }) {
    final u = ref.read(userProfileProvider);
    if (u == null) return;

    final updated = u.copyWith(
      logins: [
        ...(u.logins ?? []),
        LoginMethod(
          provider: provider,
          identifier: identifier,
          token: token,
          isPrimary: isPrimary,
        ),
      ],
    );
    ref.read(userProfileProvider.notifier).setUser(updated);
  }

  String? _getBindStatus(BuildContext context, UserModel? user, String provider) {
    if (user == null) return null;
    final p = provider.toLowerCase();

    final login = user.logins.firstWhere(
          (e) => e.provider.toLowerCase() == p,
      orElse: () => LoginMethod(provider: '', identifier: ''),
    );
    if (login.provider.isEmpty) return null;

    if (p == 'email') {
      final id = login.identifier.trim();
      return id.isNotEmpty ? id : null;
    }

    final id = login.identifier.trim();
    if (_looksLikeEmail(id)) return id;

    final email = _emailFromJwt(login.token);
    if (email != null) return email;

    return S.of(context).statusBound;
  }

  Widget _buildAccountCard(String icon, String title, {String? status, VoidCallback? onTap}) {
    final display = (status == null || status.isEmpty) ? null : _ellipsis15(status, max: 15);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: SvgPicture.asset(icon, width: 24, height: 24),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (display != null) ...[
              Text(display, style: const TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String? _emailFromJwt(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String norm(String s) => s.replaceAll('-', '+').replaceAll('_', '/').padRight(s.length + (4 - s.length % 4) % 4, '=');
      final payloadJson = utf8.decode(base64Url.decode(norm(parts[1])));
      final payload = jsonDecode(payloadJson);
      final email = payload['email']?.toString();
      return (email != null && _looksLikeEmail(email)) ? email : null;
    } catch (_) {
      return null;
    }
  }

  bool _looksLikeEmail(String s) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s);

  String _ellipsis15(String? s, {int max = 15}) {
    if (s == null || s.isEmpty) return s ?? '';
    final chars = s.characters;
    if (chars.length <= max) return s;
    return chars.take(max).toString() + '...';
  }
}

// —— Apple nonce 工具 —— //
String _randomNonce([int length = 32]) {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final rand = Random.secure();
  return List.generate(length, (_) => charset[rand.nextInt(charset.length)]).join();
}
String _sha256ofString(String input) => sha256.convert(utf8.encode(input)).toString();
