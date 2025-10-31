import 'package:flutter/services.dart';

class CachedVideoController {
  static const _ch = MethodChannel('cached_video_player');

  Future<void> setDataSource(String url, {String? userAgent, Map<String, String>? headers, bool looping = true}) async {
    await _ch.invokeMethod('setDataSource', {
      'url': url,
      'userAgent': userAgent ?? 'djs-live/1.0',
      'headers': headers,
      'looping': looping,
    });
  }

  Future<void> play()   => _ch.invokeMethod('play');
  Future<void> pause()  => _ch.invokeMethod('pause');
  Future<void> seekTo(Duration pos) => _ch.invokeMethod('seekTo', {'ms': pos.inMilliseconds});
  Future<void> dispose() => _ch.invokeMethod('dispose');
}
