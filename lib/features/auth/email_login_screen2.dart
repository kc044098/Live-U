import 'package:djs_live_stream/features/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EmailLoginScreen2 extends StatefulWidget {
  const EmailLoginScreen2({super.key});

  @override
  State<EmailLoginScreen2> createState() => _EmailLoginScreen2State();
}

class _EmailLoginScreen2State extends State<EmailLoginScreen2> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isCodeSent = false;

  void _onSendCode() {
    setState(() => _isCodeSent = true);
    Fluttertoast.showToast(msg: '驗證碼已發送');
  }

  void _onLoginPressed() {
    // 假數據：登錄成功
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
      body: SafeArea(
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

              // 驗證碼 + 獲取驗證碼
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

              // 切換賬號密碼登錄
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text(
                  '账号密码登录',
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
                  _buildSocialIcon('assets/icon_google.svg'),
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
    );
  }

  Widget _buildSocialIcon(String assetPath) {
    return Container(
      width: 88,
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SvgPicture.asset(assetPath),
    );
  }
}