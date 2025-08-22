// 先用簡化版，之後替換為原生 ExoPlayer/AVPlayer。
import 'dart:convert';

import 'dart:async';
import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

typedef CancelToken = void Function();

class PlatformPrefetch {
  static CancelToken prefetchHlsHead(String m3u8Url, {int headSegments = 4}) {
    bool cancelled = false;

    Future<void> _run() async {
      try {
        final playlist = await _fetch(m3u8Url);
        final segUrls = _parseHeadSegments(playlist, headSegments);
        for (final u in segUrls) {
          if (cancelled) break;
          await _fetchAndCache(u);
        }
      } catch (e) {
        print('Prefetch error: $e');
      }
    }

    _run();
    return () => cancelled = true;
  }

  static Future<String> _fetch(String url) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('Failed to load: $url');
    }
    final contents = await response.transform(const Utf8Decoder()).join();
    return contents;
  }

  static List<String> _parseHeadSegments(String m3u8, int n) {
    final lines = m3u8.split('\n');
    final segUrls = <String>[];
    for (final line in lines) {
      if (line.isNotEmpty && !line.startsWith('#')) {
        segUrls.add(line.trim());
        if (segUrls.length >= n) break;
      }
    }
    return segUrls;
  }

  static Future<void> _fetchAndCache(String url) async {
    final file = await DefaultCacheManager().getSingleFile(url);
    print('Cached segment: $url at ${file.path}');
  }
}