import 'package:djs_live_stream/features/auth/login_screen.dart';
import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:djs_live_stream/features/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
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
      await repo.logout();
    } catch (e) {
      debugPrint('logout api failed: $e');
    }

    final user = ref.read(userProfileProvider);

    bool isGoogleLogin = (user?.google?.isNotEmpty ?? false);
    try {
      if (isGoogleLogin) {
        await authService.signOut();
      }
    } catch (_) {}

    ref.read(userProfileProvider.notifier).logout();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context); // ← 取用多語

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
            Text(s.logout, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(s.logoutConfirmMessage, style: const TextStyle(fontSize: 14, color: Colors.black54)),
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
                    child: Text(s.commonCancel, style: const TextStyle(color: Colors.black)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    child: Ink(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: _loading ? null : () => _doLogout(context),
                        child: SizedBox(
                          height: 40,
                          child: Center(
                            child: Text(
                              s.commonConfirm,
                              style: const TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
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

