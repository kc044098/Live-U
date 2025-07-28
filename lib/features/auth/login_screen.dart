import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../l10n/l10n.dart';
import 'google_auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final user = await _googleAuthService.signInWithGoogle(ref);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Fluttertoast.showToast(msg: 'Google 登入失敗');
    }
  }

  void _fakeLogin() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  Widget _buildLoginButton({
    required String label,
    required String iconPath,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
          minimumSize: const Size(double.infinity, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          side: const BorderSide(color: Colors.black12),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        onPressed: onPressed,
        child: SizedBox(
          width: double.infinity,
          height: 32,
          child: Stack(
            children: [
              // 文字
              Positioned(
                left: 120,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              // 圖示
              Positioned(
                left: 80,
                top: 0,
                bottom: 0,
                child: Center(
                  child: SvgPicture.asset(
                    iconPath,
                    height: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              SvgPicture.asset(
                'assets/logo_placeholder.svg',
                height: 80,
              ),
              const SizedBox(height: 28),
              const Text(
                '欢迎您的登录',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 64),
              _buildLoginButton(
                label: '通过 Facebook 登录',
                iconPath: 'assets/icon_facebook.svg',
                onPressed: _fakeLogin,
              ),
              _buildLoginButton(
                label: '通过 Google 登录',
                iconPath: 'assets/icon_google.svg',
                onPressed: _handleGoogleLogin,
              ),
              _buildLoginButton(
                label: '通过 Apple 登录',
                iconPath: 'assets/icon_apple.svg',
                onPressed: _fakeLogin,
              ),
              _buildLoginButton(
                label: '通过邮箱登录',
                iconPath: 'assets/icon_email.svg',
                onPressed: _fakeLogin,
              ),
              _buildLoginButton(
                label: '通过账号密码登录',
                iconPath: 'assets/icon_user.svg',
                onPressed: _fakeLogin,
              ),
              const SizedBox(height: 24),
              Text.rich(
                TextSpan(
                  text: '登录及代表您确认已满18岁，并同意我们的 ',
                  children: [
                    TextSpan(
                      text: '《使用条款》',
                      style: const TextStyle(color: Colors.deepPurple),
                    ),
                    const TextSpan(text: ' 和 '),
                    TextSpan(
                      text: '《主播协议》',
                      style: const TextStyle(color: Colors.deepPurple),
                    ),
                    const TextSpan(text: ' 与 '),
                    TextSpan(
                      text: '《隐私政策》',
                      style: const TextStyle(color: Colors.deepPurple),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}