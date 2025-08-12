import 'package:djs_live_stream/features/auth/providers/auth_repository_provider.dart';
import 'package:djs_live_stream/features/auth/register_screen.dart';
import 'package:djs_live_stream/features/auth/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/user_local_storage.dart';
import '../profile/profile_controller.dart';
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
  bool _isLoading = false;

  Future<void> _onLoginPressed() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final code = _codeController.text.trim();

    // 1. 驗證郵箱是否為空
    if (email.isEmpty) {
      Fluttertoast.showToast(msg: '請輸入郵箱');
      return;
    }

    // 2. 驗證郵箱格式（簡單判斷含 @ 符號）
    if (!email.contains('@')) {
      Fluttertoast.showToast(msg: '郵箱格式錯誤');
      return;
    }

    // 3. 驗證對應輸入欄位
    if (_useCodeLogin) {
      if (code.isEmpty) {
        Fluttertoast.showToast(msg: '請輸入驗證碼');
        return;
      }
    } else {
      if (password.isEmpty) {
        Fluttertoast.showToast(msg: '請輸入密碼');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = _useCodeLogin
          ? await authRepo.loginWithEmailCode(
        account: email,
        code: code,
      )
          : await authRepo.loginWithAccountPassword(
        account: email,
        password: password,
      );

      await UserLocalStorage.saveUser(user);
      ref.read(userProfileProvider.notifier).setUser(user);

      Fluttertoast.showToast(msg: '登入成功');
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      Fluttertoast.showToast(msg: '登入失敗: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      Fluttertoast.showToast(msg: '請輸入郵箱');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendEmailCode(email);
      Fluttertoast.showToast(msg: '驗證碼已發送');
    } catch (e) {
      Fluttertoast.showToast(msg: '發送失敗: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isLoading ? null : AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/arrow_back.svg',
            width: 24,
            height: 24,
          ),
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
                        suffixIcon: TextButton(
                          onPressed: _onSendCode,
                          child: const Text(
                            '获取验证码',
                            style: TextStyle(
                                color: Color(0xFFFF4D67), fontSize: 14),
                          ),
                        ),
                        hintText: '请输入验证码',
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
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        hintText: '请输入密码',
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ResetPasswordScreen()),
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
                      child: const Center(
                        child: Text(
                          '登录',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 切換按鈕（不再跳頁）
                  OutlinedButton(
                    onPressed: () =>
                        setState(() => _useCodeLogin = !_useCodeLogin),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: Text(
                      _useCodeLogin ? '账号密码登录' : '验证码登录',
                      style: const TextStyle(color: Colors.black, fontSize: 16),
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
                            style:
                            TextStyle(fontSize: 18, color: Color(0xFF616161))),
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
                        onTap: _handleGoogleLogin,
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
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
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