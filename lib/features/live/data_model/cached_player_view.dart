import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class CachedPlayerView extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final bool autoPlayOnAttach;
  final String? coverUrl;
  final VoidCallback? onFirstFrame;

  const CachedPlayerView({
    super.key,
    required this.url,
    this.headers,
    this.autoPlayOnAttach = true,
    this.coverUrl,
    this.onFirstFrame,
  });

  @override
  State<CachedPlayerView> createState() => CachedPlayerViewState();
}

class CachedPlayerViewState extends State<CachedPlayerView> with WidgetsBindingObserver {
  MethodChannel? _ch;
  bool _attached = false;
  bool _wasPlayingBeforePause = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ch?.invokeMethod("release");
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_ch == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
      // 回前台：如果先前有 attach，就補一次 attach；必要時恢復播放
        if (!_attached) {
          await attach();
        }
        if (_wasPlayingBeforePause) {
          await play();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      // 退到後台：記錄是否在播 → 暫停並 detach，釋放 Surface/decoder
        try {
          final playing = await _ch!.invokeMethod<bool>("isPlaying");
          _wasPlayingBeforePause = playing == true;
        } catch (_) {
          _wasPlayingBeforePause = false;
        }
        await pause();
        await detach();
        break;
      case AppLifecycleState.detached:
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    return AndroidView(
      viewType: "cached_video_player/view",
      onPlatformViewCreated: (id) async {
        _ch = MethodChannel("cached_video_player/view_$id");

        // ★ 接住 Android 傳回來的首幀事件
        _ch!.setMethodCallHandler((call) async {
          if (call.method == "onFirstFrame") {
            widget.onFirstFrame?.call();
          }
        });

        await _ch!.invokeMethod("setDataSource", {
          "url": widget.url,
          "userAgent": "djs-live/1.0",
          "headers": widget.headers,
          "autoPlay": false,
          "looping": true,
          "coverUrl": widget.coverUrl,
        });

        // 進入即 attach（你剛找到的關鍵），並依參數自動播放
        await attach();
        _attached = true;
        if (widget.autoPlayOnAttach) {
          await play();
        }
      },
      layoutDirection: TextDirection.ltr,
    );
  }

  Future<void> attach() async { await _ch?.invokeMethod("attach"); _attached = true; }
  Future<void> detach() async { await _ch?.invokeMethod("detach"); _attached = false; }
  Future<void> play()   async => _ch?.invokeMethod("play");
  Future<void> pause()  async => _ch?.invokeMethod("pause");

  @override
  void didUpdateWidget(covariant CachedPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url != oldWidget.url && _ch != null) {
      _ch!.invokeMethod("setDataSource", {
        "url": widget.url,
        "userAgent": "djs-live/1.0",
        "headers": widget.headers,
        "autoPlay": false,
        "looping": true,
        "coverUrl": widget.coverUrl,
      });
      // 切新來源後重新 attach，避免黑屏
      attach();
      if (widget.autoPlayOnAttach) play();
    }
  }
}