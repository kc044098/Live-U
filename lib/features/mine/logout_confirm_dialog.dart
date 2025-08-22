import 'package:djs_live_stream/features/auth/login_screen.dart';
import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:djs_live_stream/features/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/google_auth_service.dart';
class LogoutConfirmDialog extends ConsumerStatefulWidget {
  const LogoutConfirmDialog({super.key});

  @override
  ConsumerState<LogoutConfirmDialog> createState() => _LogoutConfirmDialogState();
}

class _LogoutConfirmDialogState extends ConsumerState<LogoutConfirmDialog> {
  bool _loading = false;

  Future<void> _doLogout(BuildContext context) async {
    if (_loading) return;
    setState(() => _loading = true);

    final authService = GoogleAuthService();
    final repo = ref.read(userRepositoryProvider);

    try {
      // 1) 先通知後端註銷（即使失敗，仍會做本地清除）
      await repo.logout();
    } catch (e) {
      // 這裡不擋登出流程，可視需要提示
      debugPrint('logout api failed: $e');
    }

    try {
      // 2) 清第三方登入 Session（若有）
      await authService.signOut();
    } catch (_) {}

    // 3) 清本地使用者狀態 / token / 快取（依你專案的 provider 做）
    ref.read(userProfileProvider.notifier).logout();

    if (!mounted) return;
    // 4) 回登入頁
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon_logout_warning.png', width: 80),
            const SizedBox(height: 16),
            const Text('退出登陆', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('确认退出当前账号？', style: TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD8D8D8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('取消', style: TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _doLogout(context),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                        ),
                      ),
                      child: Text('确认',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}