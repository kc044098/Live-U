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

enum LegalDoc { terms, anchor, privacy }

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
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _anchorTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  void _openDoc(LegalDoc doc) {
    final t = S.of(context);

    late final String title;
    late final String url;

    switch (doc) {
      case LegalDoc.terms:
        title = t.termsOfUse;
        url = 'https://www.liveu.live/teams_of_liveu.html';
        break;
      case LegalDoc.anchor:
        title = t.anchorAgreement;
        url = 'https://www.liveu.live/refund_policy.html';
        break;
      case LegalDoc.privacy:
        title = t.privacyPolicy;
        url = 'https://www.liveu.live/privacy_policy.html';
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WebDocPage(title: title, url: url)),
    );
  }

  Future<void> _handleGoogleLogin() async {

    if (Firebase.apps.isEmpty) {
      Fluttertoast.showToast(msg: S.of(context).initializingWait);
      return;
    }

    setState(() => _isLoading = true);
    final user = await _googleAuthService.signInWithGoogle(ref);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Fluttertoast.showToast(msg: S.of(context).signInFailedGoogle);
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
    if (Firebase.apps.isEmpty) {
      Fluttertoast.showToast(msg: S.of(context).initializingWait);
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
        Fluttertoast.showToast(msg: S.of(context).signInFailedFacebook);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Facebook 登入失敗 e: $e ');
      Fluttertoast.showToast(msg: S.of(context).signInFailedFacebook);
    }
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
    final t = S.of(context);

    _termsTap.onTap   = () => _openDoc(LegalDoc.terms);
    _anchorTap.onTap  = () => _openDoc(LegalDoc.anchor);
    _privacyTap.onTap = () => _openDoc(LegalDoc.privacy);

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
                        Text(
                          t.loginWelcomeTitle,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 64),

                        _buildLoginButton(
                          label: t.loginWithFacebook,
                          iconPath: 'assets/icon_facebook.svg',
                          onPressed: _handleFacebookLogin,
                        ),
                        _buildLoginButton(
                          label:  t.loginWithGoogle,
                          iconPath: 'assets/icon_google.svg',
                          onPressed: _handleGoogleLogin,
                        ),
                        _buildLoginButton(
                          label: t.loginWithApple,
                          iconPath: 'assets/icon_apple.svg',
                          onPressed: _handleAppleLogin,
                        ),
                        _buildLoginButton(
                          label: t.loginWithEmail,
                          iconPath: 'assets/icon_email.svg',
                          onPressed: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const EmailLoginScreen()));
                          },
                        ),
                        _buildLoginButton(
                          label: t.loginWithAccount,
                          iconPath: 'assets/icon_user.svg',
                          onPressed: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const AccountLoginScreen()));
                          },
                        ),
                        const SizedBox(height: 24),

                        Text.rich(
                          TextSpan(
                            text: t.consentLoginPrefix,
                            children: [
                              TextSpan(
                                text: t.termsOfUse,
                                style: const TextStyle(color: Color(0xFFFF4D67)),
                                recognizer: _termsTap,
                              ),
                              TextSpan(text: t.andWord),
                              TextSpan(
                                text: t.anchorAgreement,
                                style: const TextStyle(color: Color(0xFFFF4D67)),
                                recognizer: _anchorTap,
                              ),
                              TextSpan(text: t.andWord),
                              TextSpan(
                                text: t.privacyPolicy,
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