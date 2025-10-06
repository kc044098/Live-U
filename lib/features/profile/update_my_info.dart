import 'package:djs_live_stream/features/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/user_local_storage.dart';
import '../../l10n/l10n.dart';
import '../home/home_screen.dart';
import '../mine/user_repository_provider.dart';
import 'update_my_info2.dart';

class UpdateMyInfoPage extends ConsumerStatefulWidget {
  const UpdateMyInfoPage({super.key});

  @override
  ConsumerState<UpdateMyInfoPage> createState() => _UpdateMyInfoPageState();
}

class _UpdateMyInfoPageState extends ConsumerState<UpdateMyInfoPage> {
  String? _selectedGender; // "female" or "male"

  Future<void> _onNext() async {
    if (_selectedGender == null) {
      Fluttertoast.showToast(msg: "請先選擇性別");
      return;
    }

    final sexValue = _selectedGender == 'male' ? 1 : 2;
    final user = ref.watch(userProfileProvider);
    final repo = ref.read(userRepositoryProvider);
    final updatedUser = user?.copyWith(sex: sexValue);
    ref.read(userProfileProvider.notifier).setUser(updatedUser!);
    UserLocalStorage.saveUser(updatedUser);

    if (_selectedGender == 'male') {
      // 男生 → 回首頁並清空路由

      // 5. API 上傳
      await repo.updateMemberInfo({'sex': 1});

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } else {
      // 女生 → 進入第二步
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UpdateMyInfoPage2()),
      );
    }
  }

  void _onSkip() {
    final user = ref.watch(userProfileProvider);
    final updatedUser = user?.copyWith(sex: 3);
    ref.read(userProfileProvider.notifier).setUser(updatedUser!);
    UserLocalStorage.saveUser(updatedUser);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UpdateMyInfoPage2()),
    );
  }

  Widget _buildGenderCard({
    required String gender,
    required String bgImage,
  }) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () => setState(() => _selectedGender = gender),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.red : Colors.transparent,
            width: 2,
          ),
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    const totalSteps = 4;
    const currentStep = 1;
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
        Fluttertoast.showToast(msg: t.setupToastSetProfileFirst);
        return false; // 阻止返回鍵
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // 不顯示返回按鈕
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressIndicator(),
                      const SizedBox(height: 20),
                      Text(t.setupPleaseChoose,
                          style: const TextStyle(fontSize: 14, color: Colors.black)),
                      const SizedBox(height: 8),
                      Text(t.setupYourGender,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(t.setupGenderImmutable,
                          style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 30),

                      _buildGenderCard(gender: "female", bgImage: "assets/pic_girl.png"),
                      _buildGenderCard(gender: "male", bgImage: "assets/pic_boy.png"),

                      const Spacer(), // 保持底部按鈕推到底部
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
                                t.setupNext, style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _onSkip,
                          child: Text(
                              t.setupSkip, style: TextStyle(color: Color(0xFFFF4D67), fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}