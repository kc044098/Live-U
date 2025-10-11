import 'package:djs_live_stream/push/push_service.dart';
import 'package:flutter/widgets.dart';

class AppLifecycle with WidgetsBindingObserver {
  AppLifecycle._();
  static final AppLifecycle I = AppLifecycle._();

  bool isForeground = false;
  final List<VoidCallback> _onResumed = [];

  void init() {
    WidgetsBinding.instance.addObserver(this);
    isForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  void addOnResumed(VoidCallback cb) => _onResumed.add(cb);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    isForeground = (state == AppLifecycleState.resumed);
    if (isForeground) {
      PushService.I.cancelIncomingCallNotificationIfAny();
    }
  }
}
