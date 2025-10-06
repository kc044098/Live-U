import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models/user_model.dart';
import '../../l10n/l10n.dart';
import '../auth/LoginMethod.dart';
import '../profile/profile_controller.dart';
import 'add_email_account_page.dart';
import 'account_info_page.dart';
class AccountManagePage extends ConsumerWidget {
  const AccountManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== 帳號欄位 =====
          if (user?.isBroadcaster ?? false) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: SvgPicture.asset('assets/icon_account.svg', width: 24, height: 24),
                title: Text(s.accountLabel),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayEmail,
                      style: TextStyle(
                        color: emailBound ? Colors.black54 : Colors.red,
                        fontSize: 14,
                      ),
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
          // ===== 郵箱欄位 + 提示 =====
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
                  child: Text(
                    s.emailBindHint,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: SvgPicture.asset('assets/icon_email.svg', width: 24, height: 24),
                  title: Text(s.emailLabel),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayEmail,
                        style: TextStyle(
                          color: emailBound ? Colors.black54 : Colors.red,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right, color: Colors.black38, size: 20),
                    ],
                  ),
                  onTap: () async {
                    final user = ref.read(userProfileProvider);
                    final hasEmail = user?.logins.any((login) => login.provider == 'email') ?? false;

                    if (!hasEmail) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddEmailAccountPage()),
                      );

                      if (result != null && result is String && result.isNotEmpty) {
                        final updatedUser = user?.copyWith(
                          logins: [
                            ...user.logins ?? [],
                            LoginMethod(provider: 'email', identifier: result, isPrimary: false),
                          ],
                        );
                        if (updatedUser != null) {
                          ref.read(userProfileProvider.notifier).setUser(updatedUser);
                        }
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

          // ===== 其他第三方帳號 =====
          _buildAccountCard('assets/icon_facebook.svg', 'Facebook', status: facebookStatus),
          const SizedBox(height: 20),
          _buildAccountCard('assets/icon_google.svg', 'Google', status: googleStatus),
          const SizedBox(height: 20),
          _buildAccountCard('assets/icon_apple.svg', 'Apple', status: appleStatus),
        ],
      ),
    );
  }

  String? _emailFromJwt(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      String norm(String s) => s
          .replaceAll('-', '+')
          .replaceAll('_', '/')
          .padRight(s.length + (4 - s.length % 4) % 4, '=');
      final payloadJson = utf8.decode(base64Url.decode(norm(parts[1])));
      final payload = jsonDecode(payloadJson);
      final email = payload['email']?.toString();
      return (email != null && _looksLikeEmail(email)) ? email : null;
    } catch (_) {
      return null;
    }
  }

  String? _getBindStatus(BuildContext context, UserModel? user, String provider) {
    if (user == null) return null;
    final p = provider.toLowerCase();

    final login = user.logins.firstWhere(
          (e) => e.provider.toLowerCase() == p,
      orElse: () => LoginMethod(provider: '', identifier: ''),
    );
    if (login.provider.isEmpty) return null;

    // 1) email provider：identifier 本來就是 email
    if (p == 'email') {
      final id = login.identifier.trim();
      return id.isNotEmpty ? id : null;
    }

    // 2) 其他第三方：若 identifier 本身像 email → 直接用
    final id = login.identifier.trim();
    if (_looksLikeEmail(id)) return id;

    // 3) 再嘗試從 token (JWT id_token) 把 email 解出來
    final email = _emailFromJwt(login.token);
    if (email != null) return email;

    // 4) 都拿不到就顯示「已綁定」（多語言）
    return S.of(context).statusBound;
  }

  Widget _buildAccountCard(String icon, String title, {String? status}) {
    final display = (status == null || status.isEmpty) ? null : _ellipsis15(status, max: 15);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
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
        onTap: () { /* TODO */ },
      ),
    );
  }

  bool _looksLikeEmail(String s) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(s);

  String _ellipsis15(String? s, {int max = 15}) {
    if (s == null || s.isEmpty) return s ?? '';
    final chars = s.characters;
    if (chars.length <= max) return s;
    return chars.take(max).toString() + '...';
  }
}
