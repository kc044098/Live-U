import 'package:djs_live_stream/push/push_service.dart';
import 'package:flutter/widgets.dart';

class AppLifecycle with WidgetsBindingObserver {
  AppLifecycle._();
  static final AppLifecycle I = AppLifecycle._();

  bool isForeground = false;
  final _onResumed = <VoidCallback>[];
  final _onPaused  = <VoidCallback>[];
  final _onInactive = <VoidCallback>[];
  final _onDetached = <VoidCallback>[];

  void init() {
    WidgetsBinding.instance.addObserver(this);
    isForeground = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  void addOnResumed(VoidCallback cb)  => _onResumed.add(cb);
  void addOnPaused(VoidCallback cb)   => _onPaused.add(cb);
  void addOnInactive(VoidCallback cb) => _onInactive.add(cb);
  void addOnDetached(VoidCallback cb) => _onDetached.add(cb);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    isForeground = (state == AppLifecycleState.resumed);

    if (state == AppLifecycleState.resumed) {
      // 你原本的清理
      PushService.I.cancelIncomingCallNotificationIfAny();
      for (final f in _onResumed) f();
    } else if (state == AppLifecycleState.paused) {
      for (final f in _onPaused) f();
    } else if (state == AppLifecycleState.inactive) {
      for (final f in _onInactive) f();
    } else if (state == AppLifecycleState.detached) {
      for (final f in _onDetached) f();
    }
  }
}