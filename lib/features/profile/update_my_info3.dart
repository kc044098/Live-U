import 'package:djs_live_stream/features/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import 'update_my_info4.dart';

class UpdateMyInfoPage3 extends ConsumerStatefulWidget {
  const UpdateMyInfoPage3({super.key});

  @override
  ConsumerState<UpdateMyInfoPage3> createState() => _UpdateMyInfoPage3State();
}

class _UpdateMyInfoPage3State extends ConsumerState<UpdateMyInfoPage3> {
  final TextEditingController _nicknameController = TextEditingController();

  void _onNext() {
    final t = S.of(context);
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      Fluttertoast.showToast(msg: t.setupNicknameToastEmpty);
      return;
    }

    if (nickname.length > 20) {
      Fluttertoast.showToast(msg: t.setupNicknameTooLong(20));
      return;
    }

    // 更新暱稱（原邏輯不變）
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
    final t = S.of(context);

    return WillPopScope(
      onWillPop: () async {
        Fluttertoast.showToast(msg: t.setupBlockBack);
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

              // '請填寫'
              Text(
                t.setupPleaseFill,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 8),

              // '你的暱稱'
              Text(
                t.setupYourNickname,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              // '給自己起個暱稱吧，讓大家認識你'
              Text(
                t.setupNicknameSubtitle,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: t.setupNicknamePlaceholder,
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
                  child: Center(
                    child: Text(
                      t.setupNext, // 沿用共用 key
                      style: const TextStyle(
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
                  child: Text(
                    t.setupSkip, // 沿用共用 key
                    style: const TextStyle(color: Color(0xFFFF4D67), fontSize: 16),
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
