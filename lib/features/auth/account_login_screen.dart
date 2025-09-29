import 'package:djs_live_stream/features/auth/providers/auth_repository_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/error_handler.dart';
import '../../core/user_local_storage.dart';
import '../mine/user_repository_provider.dart';
import '../profile/profile_controller.dart';
import 'auth_repository.dart';
import 'google_auth_service.dart';

// 通过账号密码登录
class AccountLoginScreen extends ConsumerStatefulWidget {
  const AccountLoginScreen({super.key});

  @override
  ConsumerState<AccountLoginScreen> createState() =>
      _AccountLoginScreenState();
}

class _AccountLoginScreenState extends ConsumerState<AccountLoginScreen> {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isLoading = false;

  Future<void> _onLoginPressed() async {
    final account = _accountController.text.trim();
    final password = _passwordController.text.trim();

    if (account.isEmpty) {
      Fluttertoast.showToast(msg: '請輸入帳號');
      return;
    }
    if (password.isEmpty) {
      Fluttertoast.showToast(msg: '請輸入密碼');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      // 1. 登錄（拿到 token）
      final user = await authRepo.loginWithAccountPassword(
        account: account,
        password: password,
      );

      // 2. 先寫入本地與 provider，確保攔截器使用的是最新 token
      await UserLocalStorage.saveUser(user);
      ref.read(userProfileProvider.notifier).setUser(user);

      // 3. 再調用會員資訊 API（用最新 token）
      final updatedUser = await userRepo.getMemberInfo(user);

      // 4. 用完整資料覆蓋
      await UserLocalStorage.saveUser(updatedUser);
      ref.read(userProfileProvider.notifier).setUser(updatedUser);

      Fluttertoast.showToast(msg: '登錄成功');
      Navigator.pushReplacementNamed(context, '/home');
    } on BadCredentialsException {
      // 明確帳密錯誤，固定友善訊息
      Fluttertoast.showToast(msg: '登錄失敗: 帳號或密碼錯誤');
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
        // 不再固定寬度，交給 Expanded 等分
        height: 60,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          // FittedBox 讓圖示在狹窄時等比縮小，避免撐爆
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SvgPicture.asset(
              assetPath,
              width: 28, // 目標大小（可依設計調整）
              height: 28,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
          _buildMainContent(),
          if (_isLoading)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '通过账号登录',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 90),

            // 帳號
            TextField(
              controller: _accountController,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset('assets/icon_user.svg'),
                ),
                hintText: '请输入账号',
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
            const SizedBox(height: 60),

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
            LayoutBuilder(
              builder: (context, constraints) {
                const double gap = 12; // 最小間距（原來 32 太大了）
                return Row(
                  children: [
                    Expanded(child: _buildSocialButton('assets/icon_facebook_2.svg')),
                    const SizedBox(width: gap),
                    Expanded(child: _buildSocialButton(
                      'assets/icon_google_2.svg',
                      onTap: _handleGoogleLogin,
                    )),
                    const SizedBox(width: gap),
                    Expanded(child: _buildSocialButton('assets/icon_apple_2.svg')),
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
}
