import 'package:djs_live_stream/features/auth/providers/auth_repository_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/error_handler.dart';
import '../../core/user_local_storage.dart';
import '../../l10n/l10n.dart';
import '../mine/user_repository_provider.dart';
import '../profile/profile_controller.dart';
import 'apple_auth_service.dart';
import 'auth_repository.dart';
import 'facebook_auth_service.dart';
import 'google_auth_service.dart';
// 通过账号密码登录（多語化版）
class AccountLoginScreen extends ConsumerStatefulWidget {
  const AccountLoginScreen({super.key});

  @override
  ConsumerState<AccountLoginScreen> createState() => _AccountLoginScreenState();
}

class _AccountLoginScreenState extends ConsumerState<AccountLoginScreen> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final AppleAuthService _appleAuthService = AppleAuthService();
  final FacebookAuthService _facebookAuthService = FacebookAuthService();

  bool _isLoading = false;

  Future<void> _onLoginPressed() async {
    final t = S.of(context);
    final account = _accountController.text.trim();
    final password = _passwordController.text.trim();

    if (account.isEmpty) {
      Fluttertoast.showToast(msg: t.pleaseEnterAccount);
      return;
    }
    if (password.isEmpty) {
      Fluttertoast.showToast(msg: t.pleaseEnterPassword);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      // 1) 登錄（拿到 token）
      final user = await authRepo.loginWithAccountPassword(
        account: account,
        password: password,
      );

      // 2) 先寫入本地與 provider（讓攔截器用最新 token）
      await UserLocalStorage.saveUser(user);
      ref.read(userProfileProvider.notifier).setUser(user);

      // 3) 再拉會員資訊（已是最新 token）
      final updatedUser = await userRepo.getMemberInfo(user);

      // 4) 覆蓋完整資料
      await UserLocalStorage.saveUser(updatedUser);
      ref.read(userProfileProvider.notifier).setUser(updatedUser);

      Fluttertoast.showToast(msg: t.loginSuccess);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on BadCredentialsException {
      Fluttertoast.showToast(msg: t.loginFailedWrongCredentials);
    } catch (e) {
      AppErrorToast.show(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSocialButton(String assetPath, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SvgPicture.asset(
              assetPath,
              width: 28,
              height: 28,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: SvgPicture.asset('assets/arrow_back.svg', width: 24, height: 24),
          onPressed: () {
            FocusScope.of(context).unfocus();
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          _buildMainContent(t),
          if (_isLoading)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent(S t) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.accountLoginTitle,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 90),

            // 帳號
            TextField(
              controller: _accountController,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset('assets/icon_user.svg'),
                ),
                hintText: t.accountHint,
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 密碼
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset('assets/icon_password.svg'),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  tooltip: _obscurePassword ? t.showPassword : t.hidePassword,
                ),
                hintText: t.passwordHint,
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // 登錄按鈕
            GestureDetector(
              onTap: _onLoginPressed,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB56B), Color(0xFFDF65F8)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    t.login,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 60),

            // Divider
            Row(
              children: [
                const Expanded(child: Divider(thickness: 1, color: Color(0xFFEEEEEE), endIndent: 24)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(t.otherLoginMethods,
                      style: const TextStyle(fontSize: 18, color: Color(0xFF616161))),
                ),
                const Expanded(child: Divider(thickness: 1, color: Color(0xFFEEEEEE), indent: 24)),
              ],
            ),
            const SizedBox(height: 48),

            // Social login
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(child: _buildSocialButton('assets/icon_facebook_2.svg', onTap: _handleFacebookLogin)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSocialButton('assets/icon_google_2.svg', onTap: _handleGoogleLogin)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSocialButton('assets/icon_apple_2.svg', onTap: _handleAppleLogin)),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    final t = S.of(context);

    if (Firebase.apps.isEmpty) {
      Fluttertoast.showToast(msg: t.initializingWait);
      return;
    }

    setState(() => _isLoading = true);
    final user = await _googleAuthService.signInWithGoogle(ref);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Fluttertoast.showToast(msg: t.signInFailedGoogle);
    }
  }

  Future<void> _handleAppleLogin() async {
    final t = S.of(context);
    if (Firebase.apps.isEmpty) { Fluttertoast.showToast(msg: t.initializingWait); return; }
    setState(() => _isLoading = true);
    final user = await _appleAuthService.signInWithAppleViaFirebase(ref);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Fluttertoast.showToast(msg: t.signInFailedApple);
    }
  }

  Future<void> _handleFacebookLogin() async {
    final t = S.of(context);
    if (Firebase.apps.isEmpty) { Fluttertoast.showToast(msg: t.initializingWait); return; }
    try {
      setState(() => _isLoading = true);
      final user = await _facebookAuthService.signInWithFacebook(ref);
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Fluttertoast.showToast(msg: t.signInFailedFacebook);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
      Fluttertoast.showToast(msg: t.signInFailedFacebook);
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
