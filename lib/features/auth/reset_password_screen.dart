import 'dart:async';

import 'package:djs_live_stream/features/auth/providers/auth_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/error_handler.dart';
import '../../l10n/l10n.dart';
import 'auth_repository.dart';

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
  bool _obscurePassword = true;

  Timer? _codeTimer;
  int _secondsLeft = 0;

  Future<void> _onSendCode() async {
    final t = S.of(context);
    if (_secondsLeft > 0) return;  // 倒數中禁止重複點
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
      _startCodeCountdown(60);     // ← 啟動 60 秒倒數
    } on EmailFormatException {
      Fluttertoast.showToast(msg: t.emailFormatError);
    } catch (e) {
      AppErrorToast.show(e); // 其它（ApiException/Dio/未知）→ 字典轉中文/英文 Toast
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onConfirm() async {
    final t = S.of(context);
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (email.isEmpty) {
      Fluttertoast.showToast(msg: t.pleaseEnterEmail);
      return;
    }
    if (!email.contains('@')) {
      Fluttertoast.showToast(msg: t.emailFormatError);
      return;
    }
    if (code.isEmpty) {
      Fluttertoast.showToast(msg: t.pleaseEnterCode);
      return;
    }
    if (newPassword.isEmpty) {
      Fluttertoast.showToast(msg: t.pleaseEnterNewPassword);
      return;
    }

    // 密碼長度與格式檢查（6-16位且允許特殊字符）
    final passwordRegex = RegExp(r'^[A-Za-z0-9!@#\$%^&*(),.?":{}|<>]{6,16}$');
    if (!passwordRegex.hasMatch(newPassword)) {
      Fluttertoast.showToast(msg: t.passwordFormatError);
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
      Fluttertoast.showToast(msg: t.passwordResetSuccess);
      if (!mounted) return;
      Navigator.pop(context);
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
                  Text(
                    t.resetTitle,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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

                  // 驗證碼
                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset('assets/icon_password.svg'),
                      ),
                      // 固定寬度，確保文字長短不影響位置
                      suffixIconConstraints: const BoxConstraints(minWidth: 100, minHeight: 48),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                          width: 92,
                          child: TextButton(
                            onPressed: _secondsLeft > 0 ? null : _onSendCode,
                            child: Text(
                              _secondsLeft > 0
                                  ? '$_secondsLeft${t.secondsSuffix}'
                                  : t.getCode,
                              style: TextStyle(
                                color: _secondsLeft > 0
                                    ? const Color(0xFFBBBBBB)
                                    : const Color(0xFFFF4D67),
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
                  const SizedBox(height: 16),

                  // 新密碼
                  TextField(
                    controller: _newPasswordController,
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
                        tooltip: _obscurePassword ? t.showPassword : t.hidePassword,
                      ),
                      hintText: t.newPasswordHint,
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    t.passwordRuleTip,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
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
                      child: Center(
                        child: Text(
                          t.confirm,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
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

  void _startCodeCountdown([int seconds = 60]) {
    _codeTimer?.cancel();
    setState(() => _secondsLeft = seconds);
    _codeTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0); // 倒數結束，可重新發送
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  void dispose() {
    _codeTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
}

