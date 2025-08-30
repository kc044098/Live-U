import 'package:djs_live_stream/features/mine/user_repository.dart';
import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';

// 依你的專案實際路徑調整
import '../../data/network/api_client.dart';
import '../../data/network/api_endpoints.dart';

class ModifyPasswordPage extends ConsumerStatefulWidget {
  const ModifyPasswordPage({super.key});

  @override
  ConsumerState<ModifyPasswordPage> createState() => _ModifyPasswordPageState();
}

class _ModifyPasswordPageState extends ConsumerState<ModifyPasswordPage> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  late final UserRepository _repo;

  bool _isSubmitting = false;
  bool _showOld = false;
  bool _showNew = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // 密碼規則：6~16 字元，允許數字/字母/常見特殊字元
  bool _isPasswordValid(String pwd) {
    final regex = RegExp(
        r'''^[A-Za-z0-9!@#$%^&*()_\-+=\[\]{}|\\;:'",.<>/?`~]{6,16}$'''
    );
    return regex.hasMatch(pwd);
  }

  Future<void> _submit() async {
    final oldPwd = _oldPasswordController.text.trim();
    final newPwd = _newPasswordController.text.trim();

    // 前端校驗
    if (oldPwd.isEmpty || newPwd.isEmpty) {
      Fluttertoast.showToast(msg: '請完整輸入密碼');
      return;
    }
    if (!_isPasswordValid(newPwd)) {
      Fluttertoast.showToast(msg: '新密碼需為 6~16 位，僅限數字/字母/特殊字符');
      return;
    }
    if (oldPwd == newPwd) {
      Fluttertoast.showToast(msg: '新密碼不可與舊密碼相同');
      return;
    }

    setState(() => _isSubmitting = true);

    // 顯示簡單的 loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      var ok  = await ref.read(userRepositoryProvider).modifyPassword(oldPwd: oldPwd, newPwd: newPwd);

      if (!mounted) return;
      Navigator.of(context).pop(); // 關閉 loading

      if (ok == true) {
        Fluttertoast.showToast(msg: '密碼修改成功');
        if (!mounted) return;
        Navigator.pop(context, true); // 返回上一頁並帶成功結果
      } else {
        Fluttertoast.showToast(msg: '密碼修改失敗');
        // 留在本頁
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // 關閉 loading
      Fluttertoast.showToast(msg: '密碼修改失敗');
    } finally {
      if (mounted) {
        // 清空輸入框
        _oldPasswordController.clear();
        _newPasswordController.clear();
        setState(() => _isSubmitting = false);
      }
    }
  }

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
              obscure: !_showOld,
              onToggle: () => setState(() => _showOld = !_showOld),
            ),
            const SizedBox(height: 20),

            // 新密碼
            _buildInputField(
              controller: _newPasswordController,
              hint: '請輸入新密碼',
              icon: Icons.lock_outline,
              obscure: !_showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
            ),
            const SizedBox(height: 50),

            // 確定按鈕
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
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
                      _isSubmitting ? '處理中...' : '確定',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
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
    required bool obscure,
    required VoidCallback onToggle,
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
              obscureText: obscure,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.black45),
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }
}