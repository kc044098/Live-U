import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:video_player/video_player.dart';

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
  // Android
  MethodChannel? _ch;

  // iOS
  VideoPlayerController? _iosVc;
  bool _iosInited = false;

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
    _iosVc?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = {
      "url": widget.url,
      "userAgent": "djs-live/1.0",
      "headers": widget.headers ?? <String, String>{},
      "autoPlay": false,
      "looping": true,
      "coverUrl": widget.coverUrl,
    };

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: "cached_video_player/view",
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onAndroidPlatformViewCreated,
        layoutDirection: TextDirection.ltr,
      );
    } else if (Platform.isIOS) {
      // iOS：用 video_player
      if (!_iosInited) {
        // 延遲初始化，避免在 build 同步 setState
        Future(() async {
          _iosVc?.dispose();
          _iosVc = VideoPlayerController.networkUrl(
            Uri.parse(widget.url),
            httpHeaders: widget.headers ?? const {},
          );
          await _iosVc!.setLooping(true);
          await _iosVc!.initialize();
          _iosInited = true;
          if (widget.autoPlayOnAttach) await _iosVc!.play();
          widget.onFirstFrame?.call();
          if (mounted) setState(() {});
        });
      }

      if (_iosVc == null || !_iosVc!.value.isInitialized) {
        // 先用封面頂著
        return widget.coverUrl != null
            ? Image.network(widget.coverUrl!, fit: BoxFit.cover)
            : const ColoredBox(color: Colors.black);
      }

      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _iosVc!.value.size.width,
          height: _iosVc!.value.size.height,
          child: VideoPlayer(_iosVc!),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  // ---------- Android only ----------
  void _onAndroidPlatformViewCreated(int id) async {
    _ch = MethodChannel("cached_video_player/view_$id");
    _ch!.setMethodCallHandler((call) async {
      if (call.method == "onFirstFrame") widget.onFirstFrame?.call();
    });
    await _ch!.invokeMethod("setDataSource", {
      "url": widget.url,
      "userAgent": "djs-live/1.0",
      "headers": widget.headers,
      "autoPlay": false,
      "looping": true,
      "coverUrl": widget.coverUrl,
    });
    await attach();
    if (widget.autoPlayOnAttach) await play();
  }

  // ---------- 共用控制面 ----------
  Future<void> attach() async {
    if (Platform.isAndroid) {
      await _ch?.invokeMethod("attach");
    } else if (Platform.isIOS) {
      // iOS 無「attach」概念；保留為 no-op
    }
    _attached = true;
  }

  Future<void> detach() async {
    if (Platform.isAndroid) {
      await _ch?.invokeMethod("detach");
    } else if (Platform.isIOS) {
      // 可選：暫停即可
      await _iosVc?.pause();
    }
    _attached = false;
  }

  Future<void> play() async {
    if (Platform.isAndroid) {
      await _ch?.invokeMethod("play");
    } else if (Platform.isIOS) {
      if (_iosVc != null && _iosVc!.value.isInitialized) await _iosVc!.play();
    }
  }

  Future<void> pause() async {
    if (Platform.isAndroid) {
      await _ch?.invokeMethod("pause");
    } else if (Platform.isIOS) {
      await _iosVc?.pause();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (Platform.isAndroid && _ch == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        if (!_attached) await attach();
        if (_wasPlayingBeforePause) await play();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        try {
          if (Platform.isAndroid) {
            final playing = await _ch!.invokeMethod<bool>("isPlaying");
            _wasPlayingBeforePause = playing == true;
          } else if (Platform.isIOS) {
            _wasPlayingBeforePause = _iosVc?.value.isPlaying == true;
          }
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
  void didUpdateWidget(covariant CachedPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.url == oldWidget.url) return;

    if (Platform.isAndroid && _ch != null) {
      _ch!.invokeMethod("setDataSource", {
        "url": widget.url,
        "userAgent": "djs-live/1.0",
        "headers": widget.headers,
        "autoPlay": false,
        "looping": true,
        "coverUrl": widget.coverUrl,
      });
      attach();
      if (widget.autoPlayOnAttach) play();
    } else if (Platform.isIOS) {
      _iosInited = false; // 讓 build 重新初始化 controller
      setState(() {});
    }
  }
}
