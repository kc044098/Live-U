import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/l10n.dart';
import '../widgets/webview_flutter.dart';
import 'account_login_screen.dart';
import 'apple_auth_service.dart';
import 'email_login_screen.dart';
import 'facebook_auth_service.dart';
import 'google_auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final AppleAuthService _appleAuthService = AppleAuthService();
  final FacebookAuthService _facebookAuthService = FacebookAuthService();
  bool _isLoading = false;
  String _appVersion = '';

  final _termsTap = TapGestureRecognizer();
  final _anchorTap = TapGestureRecognizer();
  final _privacyTap = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _loadVersion();

    _termsTap.onTap   = () => _openDoc('使用条款');
    _anchorTap.onTap  = () => _openDoc('主播协议');
    _privacyTap.onTap = () => _openDoc('隐私政策');
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _anchorTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _openDoc(String title) {
    const url = 'https://www.liveu.live/privacy_policy.html';
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WebDocPage(title: title, url: url)),
    );
  }

  Future<void> _handleGoogleLogin() async {

    if (Firebase.apps.isEmpty) {
      Fluttertoast.showToast(msg: '初始化中，請稍後再試');
      return;
    }

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

  Future<void> _handleAppleLogin() async {
    if (Firebase.apps.isEmpty) {
      Fluttertoast.showToast(msg: '初始化中，請稍後再試');
      return;
    }
    setState(() => _isLoading = true);
    final user = await AppleAuthService().signInWithAppleViaFirebase(ref);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Fluttertoast.showToast(msg: 'Apple 登入失敗');
    }
  }

  Future<void> _handleFacebookLogin() async {
    if (Firebase.apps.isEmpty) {
      Fluttertoast.showToast(msg: '初始化中，請稍後再試');
      return;
    }
    try {
      setState(() => _isLoading = true);
      final user = await _facebookAuthService.signInWithFacebook(ref);
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Fluttertoast.showToast(msg: 'Facebook 登入失敗');
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Facebook 登入失敗 e: $e ');
      Fluttertoast.showToast(msg: 'Facebook 登入失敗');
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
              builder: (ctx, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24)
                      .copyWith(bottom: 80), // 給右下角版本號留空間
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // 關鍵：讓內容可壓縮
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 64),
                        SvgPicture.asset('assets/logo_placeholder.svg', height: 80),
                        const SizedBox(height: 28),
                        const Text('欢迎您的登录',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 64),

                        _buildLoginButton(
                          label: '通过 Facebook 登录',
                          iconPath: 'assets/icon_facebook.svg',
                          onPressed: _handleFacebookLogin,
                        ),
                        _buildLoginButton(
                          label: '通过 Google 登录',
                          iconPath: 'assets/icon_google.svg',
                          onPressed: _handleGoogleLogin,
                        ),
                        _buildLoginButton(
                          label: '通过 Apple 登录',
                          iconPath: 'assets/icon_apple.svg',
                          onPressed: _handleAppleLogin,
                        ),
                        _buildLoginButton(
                          label: '通过邮箱登录',
                          iconPath: 'assets/icon_email.svg',
                          onPressed: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const EmailLoginScreen()));
                          },
                        ),
                        _buildLoginButton(
                          label: '通过账号密码登录',
                          iconPath: 'assets/icon_user.svg',
                          onPressed: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const AccountLoginScreen()));
                          },
                        ),
                        const SizedBox(height: 24),

                        Text.rich(
                          TextSpan(
                            text: '登录及代表您确认已满18岁，并同意我们的 ',
                            children: [
                              TextSpan(
                                text: '《使用条款》',
                                style: const TextStyle(color: Color(0xFFFF4D67)),
                                recognizer: _termsTap,
                              ),
                              const TextSpan(text: ' 和 '),
                              TextSpan(
                                text: '《主播协议》',
                                style: const TextStyle(color: Color(0xFFFF4D67)),
                                recognizer: _anchorTap,
                              ),
                              const TextSpan(text: ' 与 '),
                              TextSpan(
                                text: '《隐私政策》',
                                style: const TextStyle(color: Color(0xFFFF4D67)),
                                recognizer: _privacyTap,
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
                );
              },
            ),


            // 右下角版本號
            Positioned(
              right: 16,
              bottom: 16,
              child: Text(
                _appVersion,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'v ${info.version}';
    });
  }
}