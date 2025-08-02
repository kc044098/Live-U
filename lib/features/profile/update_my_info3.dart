import 'package:djs_live_stream/features/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_my_info4.dart';

class UpdateMyInfoPage3 extends ConsumerStatefulWidget {
  const UpdateMyInfoPage3({super.key});

  @override
  ConsumerState<UpdateMyInfoPage3> createState() => _UpdateMyInfoPage3State();
}

class _UpdateMyInfoPage3State extends ConsumerState<UpdateMyInfoPage3> {
  final TextEditingController _nicknameController = TextEditingController();

  void _onNext() {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      Fluttertoast.showToast(msg: "請輸入你的暱稱");
      return;
    }

    // 更新暱稱
    ref.read(userProfileProvider.notifier).updateDisplayName(nickname);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpdateMyInfoPage4()),
    );
  }

  void _onSkip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpdateMyInfoPage4()),
    );
  }

  Widget _buildProgressIndicator() {
    const totalSteps = 4;
    const currentStep = 3;
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? Colors.red : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Fluttertoast.showToast(msg: "請先設定個人資料");
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                "請填寫",
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 8),
              const Text(
                "你的暱稱",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "給自己起個暱稱吧，讓大家認識你",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // 暱稱輸入框
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "請輸入你的暱稱",
                  ),
                ),
              ),

              const Spacer(),

              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _onNext,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  height: 48,
                  child: const Center(
                    child: Text(
                      '下一步',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _onSkip,
                  child: const Text(
                    "跳過",
                    style: TextStyle(color: Color(0xFFFF4D67), fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
