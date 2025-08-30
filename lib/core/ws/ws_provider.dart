import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/providers/app_config_provider.dart';
import '../../data/locale_provider.dart';
import '../../features/profile/profile_controller.dart';
import '../ws/ws_service.dart';
import 'package:flutter/material.dart';

final wsProvider = Provider<WsService>((ref) {
  const wsUrl = 'wss://api.ludev.shop/api/im/index';
  debugPrint('[WS-PROVIDER] create instance');

  final s = WsService(url: wsUrl, headers: const {});

  Map<String, String> _lastHeaders = const {};
  DateTime _lastEnsureAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool _mapEquals(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  void ensureConnectedThrottled() {
    final now = DateTime.now();
    if (now.difference(_lastEnsureAt).inMilliseconds < 1500) {
      // 1.5 秒內不要重複要求重連
      return;
    }
    _lastEnsureAt = now;
    s.ensureConnected(); // ⚠️ 確保 WsService 內部是冪等：OPEN/CONNECTING 直接 return
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

    if (!_mapEquals(headers, _lastHeaders)) {
      _lastHeaders = Map.unmodifiable(headers);
      debugPrint('[WS-PROVIDER] headers changed -> $headers');
      s.updateHeaders(headers); // ⚠️ 確保這裡不要「無條件重連」，只更新內部狀態
      ensureConnectedThrottled();
    } else {
      // 不變就什麼都不做，避免無意義重連
    }
  }

  // 初始
  updateHeadersIfChanged();

  // 僅當「相關值真的改變」時才動作
  ref.listen(userProfileProvider, (prev, next) => updateHeadersIfChanged());
  ref.listen(localeProvider,      (prev, next) => updateHeadersIfChanged());

  ref.onDispose(() => s.close());
  return s;
});
