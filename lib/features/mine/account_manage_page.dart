import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models/user_model.dart';
import '../auth/LoginMethod.dart';
import '../profile/profile_controller.dart';
import 'add_email_account_page.dart';
import 'account_info_page.dart';

class AccountManagePage extends ConsumerWidget {
  const AccountManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);

    final googleStatus = _getBindStatus(user, 'google');
    final facebookStatus = _getBindStatus(user, 'facebook');
    final appleStatus = _getBindStatus(user, 'apple');
    final isMale = user?.extra?['gender'] == 'male';

    return Scaffold(
      appBar: AppBar(
        title: const Text('賬號管理', style: TextStyle(fontSize: 16, color: Colors.black)),
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
          if (!isMale) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: SvgPicture.asset('assets/icon_account.svg',
                    width: 24, height: 24),
                title: const Text('賬號'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.displayName ?? '',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const Icon(Icons.chevron_right,
                        color: Colors.black38, size: 20),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AccountInfoPage(
                              avatarUrl: user?.avatarUrl ?? '',
                              modifyType: 'account',
                            )),
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
                  child: const Text(
                    '綁定郵箱，隨時接收有趣的活動、新功能升級、推薦獎勵等信息',
                    style: TextStyle(fontSize: 12, color: Colors.red),
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
                  title: const Text('郵箱'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getBindStatus(user, 'email') ?? '待綁定',
                        style: TextStyle(
                          color: _getBindStatus(user, 'email') == null ? Colors.red : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
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
                        MaterialPageRoute(builder: (_) => AccountInfoPage(avatarUrl: user!.avatarUrl ?? '', modifyType: 'email')),
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

  String? _getBindStatus(UserModel? user, String provider) {
    if (user == null) return null;
    final login = user.logins.firstWhere(
          (e) => e.provider.toLowerCase() == provider,
      orElse: () => LoginMethod(provider: '', identifier: ''),
    );
    if (login.provider.isEmpty) return null;
    return login.identifier.isNotEmpty ? login.identifier : null;
  }

  Widget _buildAccountCard(String icon, String title, {String? status}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: SvgPicture.asset(icon, width: 24, height: 24),
        title: Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        trailing: (status != null && status.isNotEmpty)
            ? Text(status, style: const TextStyle(fontSize: 14, color: Colors.black54))
            : const Icon(Icons.chevron_right, color: Colors.black38),
        onTap: () {
          // TODO: 跳轉對應綁定邏輯
        },
      ),
    );
  }
}
