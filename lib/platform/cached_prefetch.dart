import 'package:flutter/services.dart';

class CachedPrefetch {
  static const _ch = MethodChannel('cached_video_player');

  /// 回傳一個 handleId，之後可取消
  static Future<String> mp4Head(String url, {int bytes = 3 * 1024 * 1024, Map<String, String>? headers}) async {
    final id = await _ch.invokeMethod<String>('prefetchMp4Head', {
      'url': url,
      'bytes': bytes,
      'headers': headers,
    });
    return id!;
  }

  static Future<void> cancel(String handleId) {
    return _ch.invokeMethod('cancelPrefetch', {'id': handleId});
  }
}
