import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_handler.dart';
import '../../l10n/l10n.dart';
import '../auth/providers/auth_repository_provider.dart';

class AddEmailAccountPage extends ConsumerStatefulWidget {
  const AddEmailAccountPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AddEmailAccountPage> createState() => _AddEmailAccountPageState();
}

class _AddEmailAccountPageState extends ConsumerState<AddEmailAccountPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController  = TextEditingController();

  bool _isLoading = false;
  Timer? _codeTimer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _codeTimer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  // 發送驗證碼
  Future<void> _onSendCode() async {
    if (_secondsLeft > 0) return;
    final s = S.of(context);
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      Fluttertoast.showToast(msg: s.pleaseEnterEmail);
      return;
    }
    if (!email.contains('@')) {
      Fluttertoast.showToast(msg: s.emailFormatError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.sendEmailCode(email);     // ← 與 ResetPasswordScreen 相同的發碼接口
      Fluttertoast.showToast(msg: s.codeSent); // 本地化字串與 Reset 相同
      _startCodeCountdown(60);
    } catch (e) {
      AppErrorToast.show(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 綁定郵箱（ApiEndpoints.emailBind: {email, code}）
  Future<void> _onConfirm() async {
    final s = S.of(context);
    final email = _emailController.text.trim();
    final code  = _codeController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      Fluttertoast.showToast(msg: s.addEmailToastInvalid);
      return;
    }
    if (code.isEmpty) {
      Fluttertoast.showToast(msg: s.addEmailToastNeedCode);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      // 建議在 AuthRepository 內新增 bindEmail，見文末補丁
      await authRepo.bindEmail(email: email, code: code);

      Fluttertoast.showToast(msg: s.statusSuccess);
      if (!mounted) return;
      Navigator.pop(context, email);
    } catch (e) {
      AppErrorToast.show(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Text(s.addEmailTitle, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      s.addEmailSubtitle,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
                    ),
                    const SizedBox(height: 50),

                    // 郵箱輸入框
                    _buildInputField(
                      controller: _emailController,
                      hint: s.addEmailHintEmail,
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 20),

                    // 驗證碼輸入框（帶倒數按鈕）
                    _buildInputField(
                      controller: _codeController,
                      hint: s.addEmailHintCode,
                      icon: Icons.lock_outline,
                      trailing: SizedBox(
                        width: 100,
                        child: TextButton(
                          onPressed: (_secondsLeft > 0 || _isLoading) ? null : _onSendCode,
                          child: Text(
                            _secondsLeft > 0 ? '${_secondsLeft}s' : s.addEmailGetCode,
                            style: TextStyle(
                              color: (_secondsLeft > 0 || _isLoading)
                                  ? const Color(0xFFBBBBBB)
                                  : const Color(0xFFFF4D67),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),

                    // 確定按鈕
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onConfirm,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: EdgeInsets.zero,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              s.addEmailConfirm,
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.05),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    Widget? trailing,
  }) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black45),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                border: InputBorder.none,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
