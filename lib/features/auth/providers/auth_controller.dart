
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../../core/user_local_storage.dart';
import '../../../globals.dart';
import '../../../routes/app_routes.dart';
import '../../profile/profile_controller.dart';

class AuthService {
  // 只存 read 函式，UI/非 UI 都可傳入 ref.read
  final T Function<T>(ProviderListenable<T>) read;
  AuthService(this.read);

  static bool _routing = false;

  Future<void> routeOnLaunch(BuildContext ctx) async {
    final user  = await UserLocalStorage.getUser();
    final token = user?.primaryLogin?.token ?? '';

    if (token.isEmpty) {
      _toLogin();
      return;
    }

    // 恢復到內存，直接進首頁
    read(userProfileProvider.notifier).state = user;
    _goHome();
  }

  Future<void> forceLogout({String? tip}) async {
    if (_routing) return;
    _routing = true;
    try {
      await UserLocalStorage.clear();
      read(userProfileProvider.notifier).state = null;

      final ctx = rootNavigatorKey.currentContext;
      if (ctx != null) {
        Navigator.of(ctx, rootNavigator: true)
            .pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
      }
      if (tip?.isNotEmpty == true) {
        Fluttertoast.showToast(msg: tip!);
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 400), () => _routing = false);
    }
  }

  void _goHome() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    Navigator.of(ctx, rootNavigator: true)
        .pushNamedAndRemoveUntil(AppRoutes.home, (r) => false);
  }

  void _toLogin() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    Navigator.of(ctx, rootNavigator: true)
        .pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
  }
}
