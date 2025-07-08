// # 主頁面含 BottomNavigationBar
import 'start_live_page.dart';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import 'live_list_page.dart';
import 'mine_page.dart';
import 'message_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    LiveListPage(),        // 首頁
    const MessagePage(),      // 訊息（請確保你有這個 page）
    const StartLivePage(),    // 直播
    const MinePage(),         // 我的
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        selectedLabelStyle: const TextStyle(color: Colors.black),
        unselectedLabelStyle: const TextStyle(color: Colors.black54),
        backgroundColor: Colors.white,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: S.of(context).home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: S.of(context).message,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videocam),
            label: S.of(context).live,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: S.of(context).me,
          ),
        ],
      ),
    );
  }
}
