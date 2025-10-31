import 'package:djs_live_stream/features/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluttertoast/fluttertoast.dart';
import '../../l10n/l10n.dart';
import 'update_my_info3.dart';

class UpdateMyInfoPage2 extends ConsumerStatefulWidget {
  const UpdateMyInfoPage2({super.key});

  @override
  ConsumerState<UpdateMyInfoPage2> createState() => _UpdateMyInfoPage2State();
}

class _UpdateMyInfoPage2State extends ConsumerState<UpdateMyInfoPage2> {
  final TextEditingController _ageController = TextEditingController();

  void _onNext() {
    final t = S.of(context);
    final ageText = _ageController.text.trim();
    if (ageText.isEmpty) {
      Fluttertoast.showToast(msg: t.setupAgeToastEmpty);
      return;
    }

    final age = int.tryParse(ageText);
    if (age == null || age < 18) {
      Fluttertoast.showToast(msg: t.setupAgeToastMin18);
      return;
    }

    ref.read(userProfileProvider.notifier).updateExtraField('age', age);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpdateMyInfoPage3()),
    );
  }

  void _onSkip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpdateMyInfoPage3()),
    );
  }

  Widget _buildProgressIndicator() {
    const totalSteps = 4;
    const currentStep = 2; // 第二步
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
    final t = S.of(context);                                  // ← 新增

    return Scaffold(
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
            Text(t.setupPleaseFill,                            // ← 改（移除 const）
                style: const TextStyle(fontSize: 14, color: Colors.black)),
            const SizedBox(height: 8),

            // '你的年齡'
            Text(t.setupYourAge,                               // ← 改
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),

            // '年齡需達到18歲以上，才能使用'
            Text(t.setupAgeRequirement,                        // ← 改
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 30),

            // 年齡輸入框
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: t.setupAgePlaceholder,       // ← 改
                      ),
                    ),
                  ),
                  Text(t.setupAgeUnitYear,                     // ← 改
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),

            const Spacer(),

            // 下一步按鈕
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
                    t.setupNext,
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
                child: Text(
                  S.of(context).setupSkip,
                  style: TextStyle(color: Color(0xFFFF4D67), fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
