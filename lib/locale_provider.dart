import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale; // null = 跟隨系統
  Locale? get locale => _locale;

  void followSystem() { // 可在「語言設定」提供一鍵跟隨
    _locale = null;
    notifyListeners();
  }

  void setLocale(Locale l) {
    _locale = l;
    notifyListeners();
  }

  // 若你想在啟動時「一次性」用系統語言初始化（可選）
  void setFromSystem(Locale? sys) {
    if (sys?.languageCode.toLowerCase() == 'zh') {
      _locale = const Locale('zh');
    } else {
      _locale = const Locale('en');
    }
    notifyListeners();
  }
}
