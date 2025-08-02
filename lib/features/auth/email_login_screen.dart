import 'package:djs_live_stream/features/auth/register_screen.dart';
import 'package:djs_live_stream/features/auth/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'email_login_screen2.dart';
import 'google_auth_service.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isLoading = false;

  void _onLoginPressed() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/arrow_back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
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
                  const Text(
                    '通过邮箱登录',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 90),

                  // Email
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset('assets/icon_email2.svg'),
                      ),
                      hintText: '请输入邮箱账号',
                      filled: true,
                      fillColor: Color(0xFFFAFAFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
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
                        onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                      ),
                      hintText: '请输入密码',
                      filled: true,
                      fillColor: Color(0xFFFAFAFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
                        );
                      },
                      child: const Text(
                        '忘记密码 ？',
                        style: TextStyle(
                            color: Color(0xFFFF4D67),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xFFFF4D67),
                            decorationThickness: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login Button
                  Center(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB56B), Color(0xFFDF65F8)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Text(
                          '登录',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 验证码登录
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmailLoginScreen2()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Text(
                      '验证码登录',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Divider
                  Row(
                    children: const [
                      Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Color(0xFFEEEEEE),
                            endIndent: 24,
                          )),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('其他方式登录',
                            style: TextStyle(
                                fontSize: 18, color: Color(0xFF616161))),
                      ),
                      Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Color(0xFFEEEEEE),
                            indent: 24,
                          )),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // Social login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialIcon('assets/icon_facebook.svg'),
                      const SizedBox(width: 32),
                      _buildSocialIcon(
                        'assets/icon_google.svg',
                        onTap: _handleGoogleLogin, // Google 登錄
                      ),
                      const SizedBox(width: 32),
                      _buildSocialIcon('assets/icon_apple.svg'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('还没有账号？'),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text('立即注册',
                            style: TextStyle(
                                color: Color(0xFFFF4D67),
                                decoration: TextDecoration.underline,
                                decorationColor: Color(0xFFFF4D67),
                                decorationThickness: 1.5)),
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
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(String assetPath, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 60,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SvgPicture.asset(assetPath),
      ),
    );
  }

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
}
