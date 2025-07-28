import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ModifyPasswordPage extends StatefulWidget {
  const ModifyPasswordPage({super.key});

  @override
  State<ModifyPasswordPage> createState() => _ModifyPasswordPageState();
}

class _ModifyPasswordPageState extends State<ModifyPasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('修改密碼', style: TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              '密碼6~16字符，只能包括數字、字母或者特殊字符',
              style: TextStyle(fontSize: 14, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 40),

            // 舊密碼
            _buildInputField(
              controller: _oldPasswordController,
              hint: '請輸入舊密碼',
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 20),

            // 新密碼
            _buildInputField(
              controller: _newPasswordController,
              hint: '請輸入新密碼',
              icon: Icons.lock_outline,
            ),
            const SizedBox(height: 50),

            // 確定按鈕
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final oldPwd = _oldPasswordController.text.trim();
                  final newPwd = _newPasswordController.text.trim();

                  if (oldPwd.isEmpty || newPwd.isEmpty) {
                    Fluttertoast.showToast(msg: '請完整輸入密碼');
                    return;
                  }
                  // TODO: 調用修改密碼 API
                  print('修改密碼: 舊密碼=$oldPwd, 新密碼=$newPwd');

                  Navigator.pop(context, true); // 返回結果
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
                  child: const Center(
                    child: Text('確定', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
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
              obscureText: true,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}