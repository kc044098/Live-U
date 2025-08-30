import 'package:djs_live_stream/features/auth/providers/auth_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _isLoading = false;

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

  Future<void> _onConfirm() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    // 郵箱是否輸入
    if (email.isEmpty) {
      Fluttertoast.showToast(msg: '請輸入郵箱');
      return;
    }

    // 郵箱格式檢查
    if (!email.contains('@')) {
      Fluttertoast.showToast(msg: '郵箱格式錯誤');
      return;
    }

    // 驗證碼是否輸入
    if (code.isEmpty) {
      Fluttertoast.showToast(msg: '請輸入驗證碼');
      return;
    }

    // 新密碼是否輸入
    if (newPassword.isEmpty) {
      Fluttertoast.showToast(msg: '請輸入新密碼');
      return;
    }

    // 密碼長度與格式檢查（6-16位且允許特殊字符）
    final passwordRegex = RegExp(r'^[A-Za-z0-9!@#\$%^&*(),.?":{}|<>]{6,16}$');
    if (!passwordRegex.hasMatch(newPassword)) {
      Fluttertoast.showToast(msg: '密碼需為6-16位且只包含數字、字母或特殊字符');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      Fluttertoast.showToast(msg: '密碼已重置');
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: '重置失敗: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isLoading
          ? null
          : AppBar(
        backgroundColor: Colors.transparent,
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
                    '忘记密码',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),
                  // 郵箱
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

                  // 驗證碼
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
                            color: Color(0xFFFF4D67),
                            fontSize: 14,
                          ),
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
                  const SizedBox(height: 16),

                  // 新密碼
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset('assets/icon_password.svg'),
                      ),
                      hintText: '请输入新密码',
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    '密码6-16字符，只能包括数字、字母或者特殊字符',
                    style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 48),

                  // 確定按鈕
                  GestureDetector(
                    onTap: _onConfirm,
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
                          '确定',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
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
}