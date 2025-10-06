import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../l10n/l10n.dart';
class AddEmailAccountPage extends StatefulWidget {
  const AddEmailAccountPage({Key? key}) : super(key: key);

  @override
  State<AddEmailAccountPage> createState() => _AddEmailAccountPageState();
}

class _AddEmailAccountPageState extends State<AddEmailAccountPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codeController  = TextEditingController();

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
      body: SafeArea(
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

                // 驗證碼輸入框
                _buildInputField(
                  controller: _codeController,
                  hint: s.addEmailHintCode,
                  icon: Icons.lock_outline,
                  trailing: TextButton(
                    onPressed: () {
                      final email = _emailController.text.trim();
                      if (email.isEmpty || !email.contains('@')) {
                        Fluttertoast.showToast(msg: s.addEmailToastInvalid);
                        return;
                      }
                      // TODO: 發送驗證碼 API
                      debugPrint('發送驗證碼到: $email');
                    },
                    child: Text(s.addEmailGetCode, style: const TextStyle(color: Colors.red)),
                  ),
                ),
                const SizedBox(height: 50),

                // 確定按鈕
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
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
                      // TODO: 綁定郵箱 API
                      debugPrint('綁定郵箱: $email 驗證碼: $code');
                      Navigator.pop(context, email); // 返回輸入的郵箱
                    },
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
