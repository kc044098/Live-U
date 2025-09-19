// # 主頁面含 BottomNavigationBar

import 'package:flutter/material.dart';
import '../../core/permission_service.dart';
import '../../l10n/l10n.dart';
import '../live/data_model/home_feed_state.dart';
import '../live/gift_providers.dart';
import '../wallet/wallet_repository.dart';
import 'live_list_page.dart';
import 'mine_page.dart';
import 'message_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile/update_my_info.dart';
import '../profile/profile_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  int _liveTabIndex = 0;
  DateTime? _lastHomeRefreshAt;

  bool get _isLiveHomeTab => _selectedIndex == 0 && _liveTabIndex == 0;


  void _refreshHomeIfStale([Duration maxAge = const Duration(seconds: 15)]) {
    final now = DateTime.now();
    if (_lastHomeRefreshAt == null || now.difference(_lastHomeRefreshAt!) > maxAge) {
      ref.read(homeFeedProvider.notifier).refresh();
      _lastHomeRefreshAt = now;
    }
  }

  void _onItemTapped(int index) {
    final wasHome = _selectedIndex == 0;
    setState(() => _selectedIndex = index);

    // 切到首頁就嘗試刷新
    if (index == 0) _refreshHomeIfStale();

    // 如果使用者已在首頁又再點一次首頁，也允許刷新
    if (index == 0 && wasHome) _refreshHomeIfStale();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // 獲取錢包狀態
        final repo = ref.read(walletRepositoryProvider);
        final (gold, vipExpire) = await repo.fetchMoneyCash();

        final user = ref.read(userProfileProvider);
        if (user != null) {
          ref.read(userProfileProvider.notifier).state =
              user.copyWith(gold: gold, vipExpire: vipExpire);
        }

        // 獲取禮物列表
        await ref.read(giftListProvider.notifier).loadIfStale(const Duration(seconds: 10));
      } catch (e) {
      }

      _checkUserGender();
    });
  }

  void _checkUserGender() {
    final user = ref.read(userProfileProvider);

    if (user!.uid.isNotEmpty && (user.sex == 0)) {

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const UpdateMyInfoPage()),
            (route) => false,
      );
    }
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
    final user = ref.watch(userProfileProvider);

    final pages = [
      LiveListPage(
        onTabChanged: (index) {
          setState(() {
            _liveTabIndex = index;
          });

          // 只有當前底部是首頁，且主播 tab 切回「首页」時刷新
          if (_selectedIndex == 0 && index == 0) {
            _refreshHomeIfStale();
          }
        },
        isBroadcaster: user?.isBroadcaster ?? false,
      ),
      const MessagePage(),
      const MinePage(),
    ];

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            pages[_selectedIndex],
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
      ),
    );
  }

}