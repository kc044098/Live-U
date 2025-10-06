import 'dart:async';

import 'package:djs_live_stream/features/auth/providers/auth_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/error_handler.dart';
import '../../core/user_local_storage.dart';
import '../../l10n/l10n.dart';
import '../profile/profile_controller.dart';
import 'auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  bool _isLoading = false;

  Timer? _codeTimer;
  int _secondsLeft = 0;

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

  Future<void> _onConfirm() async {
    final t = S.of(context);
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || code.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: t.enterAllFields);
      return;
    }

    final passwordRegex = RegExp(r'^[A-Za-z0-9!@#\$%^&*(),.?":{}|<>]{6,16}$');
    if (!passwordRegex.hasMatch(password)) {
      Fluttertoast.showToast(msg: t.passwordFormatError);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.registerAccount(
        email: email,
        code: code,
        password: password,
      );

      await UserLocalStorage.saveUser(user);
      ref.read(userProfileProvider.notifier).setUser(user);

      Fluttertoast.showToast(msg: t.registerSuccess);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
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
      appBar: _isLoading ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset('assets/arrow_back.svg', width: 24, height: 24),
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
                  Text(t.registerTitle, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
                                fontSize: 14, fontWeight: FontWeight.w600,
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
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: SvgPicture.asset('assets/icon_password.svg'),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                  Text(t.passwordRuleTip, style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
                  const SizedBox(height: 48),
                  // 確定按鈕
                  GestureDetector(
                    onTap: _onConfirm,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFFB56B), Color(0xFFDF65F8)]),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(t.confirm, style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _codeTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
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
