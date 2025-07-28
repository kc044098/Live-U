// # 主頁面含 BottomNavigationBar

import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import 'live_list_page.dart';
import 'mine_page.dart';
import 'message_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile/update_my_info.dart';
import 'live_list_page.dart';
import 'message_page.dart';
import 'mine_page.dart';
import '../profile/profile_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  int _liveTabIndex = 0;

  late final List<Widget> _pages;

  bool get _isLiveHomeTab => _selectedIndex == 0 && _liveTabIndex == 0;

  @override
  void initState() {
    super.initState();
    _pages = [
      LiveListPage(
        onTabChanged: (index) {
          setState(() {
            _liveTabIndex = index;
          });
        },
      ),
      const MessagePage(),
      const MinePage(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserGender();
    });
  }

  void _checkUserGender() {
    final user = ref.read(userProfileProvider);
    final gender = user?.extra?['gender'];

    if (user!.uid.isNotEmpty && (gender == null || gender.toString().isEmpty)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UpdateMyInfoPage()),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getSvgPath(int index, bool selected) {
    switch (index) {
      case 0:
        return selected ? 'assets/icon_home_1.svg' : 'assets/icon_home_0.svg';
      case 1:
        return selected ? 'assets/icon_chat_1.svg' : 'assets/icon_chat_0.svg';
      case 2:
        return selected
            ? 'assets/icon_profile_1.svg'
            : 'assets/icon_profile_0.svg';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 這裡其實就可以監聽 user 狀態
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          _pages[_selectedIndex],
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              decoration: BoxDecoration(
                color: _isLiveHomeTab ? Colors.transparent : Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(3, (index) {
                  final isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () => _onItemTapped(index),
                    behavior: HitTestBehavior.translucent,
                    child: SizedBox(
                      width: 60,
                      height: 45,
                      child: Center(
                        child: SvgPicture.asset(
                          _getSvgPath(index, isSelected),
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}