import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/env.dart';
import '../../data/locale_provider.dart';
import '../../features/profile/profile_controller.dart';
import '../ws/ws_service.dart';
import 'package:flutter/material.dart';

final wsProvider = Provider<WsService>((ref) {
  final wsUrl = Env.wsUrl;
  debugPrint('[WS-PROVIDER] resolved ws=$wsUrl env=${Env.current}');

  final s = WsService(url: wsUrl, headers: const {});

  Map<String, String> lastHeaders = const {};
  DateTime lastEnsureAt = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? watchdog; // ← 新增：定時器

  bool _mapEquals(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  bool _hasAuth(Map<String, String> h) =>
      (h['Token']?.isNotEmpty ?? false) && (h['X-UID']?.isNotEmpty ?? false);

  void ensureConnectedThrottled() {
    final now = DateTime.now();
    if (now.difference(lastEnsureAt).inMilliseconds < 1500) return;
    lastEnsureAt = now;
    s.ensureConnected(); // 已連線 / 連線中 會直接 return
  }

  void updateHeadersIfChanged() {
    final locale = ref.read(localeProvider);
    final user   = ref.read(userProfileProvider);

    final t = user?.primaryLogin?.token?.trim();
    final u = user?.uid;
    final headers = <String, String>{
      if (t != null && t.isNotEmpty) 'Token': t,
      if (u != null && u.isNotEmpty) 'X-UID': u,
      'Accept-Language': locale.languageCode,
    };

    if (!_mapEquals(headers, lastHeaders)) {
      lastHeaders = Map.unmodifiable(headers);
      debugPrint('[WS-PROVIDER] headers changed -> $headers');
      s.updateHeaders(headers);
      ensureConnectedThrottled();
    }
  }

  // 1) 初始
  updateHeadersIfChanged();

  // 2) 監聽 auth/語系改變
  ref.listen(userProfileProvider, (prev, next) => updateHeadersIfChanged());
  ref.listen(localeProvider,      (prev, next) => updateHeadersIfChanged());

  // 3) 新增：每 30 秒做健康檢查（有憑證才檢查）
  void _startWatchdog() {
    watchdog?.cancel();
    watchdog = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_hasAuth(lastHeaders)) {
        debugPrint('[WS-PROVIDER][watchdog] not Auth. Token:${lastHeaders['Token']}, X-UID:${lastHeaders['X-UID']}.');
        return;
      }

      // 1) 若已連上但超過 65s 沒有任何接收，判定為 zombie，先關再重連
      final idle = s.idleFor;
      if (s.status == WsStatus.connected && idle > const Duration(seconds: 65)) {
        debugPrint('[WS-PROVIDER][watchdog] zombie (idle=${idle.inSeconds}s) -> forceReconnect');
        s.forceReconnect('watchdog idle');
        return;
      }

      // 2) 沒連上才去 ensureConnected（節流已內建）
      if (s.status != WsStatus.connected) {
        debugPrint('[WS-PROVIDER][watchdog] status=${s.status} -> ensureConnected()');
        ensureConnectedThrottled();
      }
    });
  }
  _startWatchdog();

  ref.onDispose(() {
    watchdog?.cancel();
    s.close();
  });

  return s;
});
