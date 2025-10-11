import 'dart:async';

import 'package:djs_live_stream/features/auth/providers/auth_repository_provider.dart';
import 'package:djs_live_stream/features/auth/register_screen.dart';
import 'package:djs_live_stream/features/auth/reset_password_screen.dart';
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

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  bool _obscurePassword = true;
  bool _useCodeLogin = false; // 切換帳號密碼 / 驗證碼登錄

  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final AppleAuthService _appleAuthService = AppleAuthService();
  final FacebookAuthService _facebookAuthService = FacebookAuthService();
  bool _isLoading = false;

  Timer? _codeTimer;
  int _secondsLeft = 0;

  Future<void> _onLoginPressed() async {
    final t = S.of(context);
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final code = _codeController.text.trim();

    if (email.isEmpty) {
      Fluttertoast.showToast(msg: t.pleaseEnterEmail);
      return;
    }
    if (!email.contains('@')) {
      Fluttertoast.showToast(msg: t.emailFormatError);
      return;
    }

    if (_useCodeLogin) {
      if (code.isEmpty) {
        Fluttertoast.showToast(msg: t.pleaseEnterCode);
        return;
      }
    } else {
      if (password.isEmpty) {
        Fluttertoast.showToast(msg: t.pleaseEnterPassword);
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = _useCodeLogin
          ? await authRepo.loginWithEmailCode(account: email, code: code)
          : await authRepo.loginWithAccountPassword(account: email, password: password);

      await UserLocalStorage.saveUser(user);
      ref.read(userProfileProvider.notifier).setUser(user);

      final updatedUser = await ref.read(userRepositoryProvider).getMemberInfo(user);
      await UserLocalStorage.saveUser(updatedUser);
      ref.read(userProfileProvider.notifier).setUser(updatedUser);

      Fluttertoast.showToast(msg: t.loginSuccess);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on BadCredentialsException {
      Fluttertoast.showToast(msg: t.loginFailedWrongCredentials);
    } on VerificationCodeException {
      Fluttertoast.showToast(msg: t.loginFailedWrongCode);
    } on EmailFormatException {
      Fluttertoast.showToast(msg: t.loginFailedEmailFormat);
    } catch (e) {
      AppErrorToast.show(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSendCode() async {
    final t = S.of(context);
    if (_secondsLeft > 0) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      Fluttertoast.showToast(msg: t.pleaseEnterEmail);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendEmailCode(email);
      Fluttertoast.showToast(msg: t.codeSent);
      _startCodeCountdown(60);
    } on EmailFormatException {
      Fluttertoast.showToast(msg: t.emailFormatError);
    } catch (e) {
      AppErrorToast.show(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: _isLoading ? null : AppBar(
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.emailLoginTitle,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 90),

                  // Email
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset('assets/icon_email2.svg'),
                      ),
                      hintText: t.emailHint,
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 根據模式切換
                  if (_useCodeLogin) ...[
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset('assets/icon_password.svg'),
                        ),
                        suffixIconConstraints: const BoxConstraints(minWidth: 100, minHeight: 48),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            width: 92,
                            child: TextButton(
                              onPressed: (_secondsLeft > 0 || _isLoading) ? null : _onSendCode,
                              child: Text(
                                _secondsLeft > 0 ? '$_secondsLeft${t.secondsSuffix}' : t.getCode,
                                style: TextStyle(
                                  color: _secondsLeft > 0 ? const Color(0xFFBBBBBB) : const Color(0xFFFF4D67),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        hintText: t.codeHint,
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ] else ...[
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SvgPicture.asset('assets/icon_password.svg'),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
                        },
                        child: Text(
                          t.forgotPassword,
                          style: const TextStyle(
                            color: Color(0xFFFF4D67),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFFF4D67),
                            decorationThickness: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],

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
                          t.login, // 原本 '登录'
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 切換按鈕（不再跳頁）
                  OutlinedButton(
                    onPressed: () => setState(() => _useCodeLogin = !_useCodeLogin),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: Text(
                      _useCodeLogin ? t.accountPasswordLogin : t.codeLogin,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 40),

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
                      const double gap = 12;
                      return Row(
                        children: [
                          Expanded(child: _buildSocialButton('assets/icon_facebook_2.svg', onTap: _handleFacebookLogin)),
                          const SizedBox(width: gap),
                          Expanded(child: _buildSocialButton('assets/icon_google_2.svg', onTap: _handleGoogleLogin)),
                          const SizedBox(width: gap),
                          Expanded(child: _buildSocialButton('assets/icon_apple_2.svg', onTap: _handleAppleLogin)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.noAccountYet),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()));
                        },
                        child: Text(
                          t.registerNow,
                          style: const TextStyle(
                            color: Color(0xFFFF4D67),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFFF4D67),
                            decorationThickness: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Loading 遮罩
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
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
            child: SvgPicture.asset(assetPath, width: 24, height: 24),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
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
    if (Firebase.apps.isEmpty) {
      Fluttertoast.showToast(msg: S.of(context).initializingWait);
      return;
    }
    setState(() => _isLoading = true);
    final user = await _appleAuthService.signInWithAppleViaFirebase(ref);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Fluttertoast.showToast(msg: S.of(context).signInFailedApple);
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

  void _startCodeCountdown([int seconds = 60]) {
    _codeTimer?.cancel();
    setState(() => _secondsLeft = seconds);
    _codeTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }
}
