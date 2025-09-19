import 'dart:io';

import 'package:flutter/services.dart';

class CachedPrefetch {
  static const _ch = MethodChannel('cached_video_player');

  static Future<String> mp4Head(String url,
      {int bytes = 3 * 1024 * 1024, Map<String, String>? headers}) async {
    if (!Platform.isAndroid) return 'noop'; // iOS 直接略過
    try {
      final id = await _ch.invokeMethod<String>('prefetchMp4Head', {
        'url': url,
        'bytes': bytes,
        'headers': headers,
      });
      return id ?? 'noop';
    } catch (_) {
      return 'noop';
    }
  }

  static Future<void> cancel(String handleId) async {
    if (!Platform.isAndroid || handleId == 'noop') return;
    try { await _ch.invokeMethod('cancelPrefetch', {'id': handleId}); } catch (_) {}
  }
}
