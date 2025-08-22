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

  final locale = ref.read(localeProvider);
  final user   = ref.read(userProfileProvider);

  final s = WsService(url: wsUrl, headers: const {});

  final initToken = user?.primaryLogin?.token?.trim();
  final initUid   = user?.uid;
  final initHeaders = <String, String>{
    if (initToken != null && initToken.isNotEmpty) 'Token': initToken,
    if (initUid != null && initUid.isNotEmpty)     'X-UID': initUid,
    'Accept-Language': locale.languageCode,
  };
  debugPrint('[WS-PROVIDER] init headers=$initHeaders');
  s.updateHeaders(initHeaders);
  s.ensureConnected(); // 若沒有 Token/UID 會 skip，log 會顯示

  ref.listen(userProfileProvider, (prev, next) {
    final t = next?.primaryLogin?.token?.trim();
    final u = next?.uid;
    final newHeaders = <String, String>{
      if (t != null && t.isNotEmpty) 'Token': t,
      if (u != null && u.isNotEmpty) 'X-UID': u,
      'Accept-Language': ref.read(localeProvider).languageCode,
    };
    debugPrint('[WS-PROVIDER] user changed -> update headers=$newHeaders');
    s.updateHeaders(newHeaders);
    s.ensureConnected();
  });

  ref.listen(localeProvider, (prev, next) {
    if (next == null) return;
    final currentToken = ref.read(userProfileProvider)?.primaryLogin?.token?.trim();
    final currentUid   = ref.read(userProfileProvider)?.uid;
    final newHeaders = <String, String>{
      if (currentToken != null && currentToken.isNotEmpty) 'Token': currentToken,
      if (currentUid != null && currentUid.isNotEmpty)     'X-UID': currentUid,
      'Accept-Language': next.languageCode,
    };
    debugPrint('[WS-PROVIDER] locale changed -> update headers=$newHeaders');
    s.updateHeaders(newHeaders);
  });

  ref.onDispose(() => s.close());
  return s;
});
