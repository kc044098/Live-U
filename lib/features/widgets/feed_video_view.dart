import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FeedVideoView extends StatefulWidget {
  final String url;
  final bool isActive;                          // 此視圖當前是否應該播放（例如 PageView 的當前頁）
  final ValueListenable<bool>? playGate;        // 全域閘門：如被其它頁覆蓋/切後台 -> 暫停
  final bool autoplay;
  final bool loop;
  final BoxFit fit;
  final Widget? placeholder;

  const FeedVideoView({
    super.key,
    required this.url,
    this.isActive = true,
    this.playGate,
    this.autoplay = true,
    this.loop = true,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  State<FeedVideoView> createState() => _FeedVideoViewState();
}

class _FeedVideoViewState extends State<FeedVideoView> with WidgetsBindingObserver {
  VideoPlayerController? _ctl;

  bool get _shouldPlay => widget.isActive && (widget.playGate?.value ?? true);

  Future<void> _setup() async {
    final p = widget.url;

    VideoPlayerController ctl;
    if (p.startsWith('http')) {
      ctl = VideoPlayerController.networkUrl(Uri.parse(p));
    } else if (p.startsWith('file://') || File(p).existsSync()) {
      ctl = VideoPlayerController.file(
        File(p.startsWith('file://') ? Uri.parse(p).toFilePath() : p),
      );
    } else {
      ctl = VideoPlayerController.asset(p);
    }

    await ctl.initialize();
    await ctl.setLooping(widget.loop);
    if (widget.autoplay && _shouldPlay) await ctl.play();

    if (!mounted) {
      ctl.dispose();
      return;
    }
    setState(() => _ctl = ctl);
  }

  void _onGateChange() {
    final c = _ctl;
    if (!mounted || c == null || !c.value.isInitialized) return;
    if (_shouldPlay) {
      c.play();
    } else {
      c.pause();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.playGate?.addListener(_onGateChange);
    _setup();
  }

  @override
  void didUpdateWidget(covariant FeedVideoView old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _ctl?.dispose();
      _ctl = null;
      _setup();
      return;
    }
    if (old.isActive != widget.isActive || old.playGate != widget.playGate) {
      old.playGate?.removeListener(_onGateChange);
      widget.playGate?.addListener(_onGateChange);
      _onGateChange();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _ctl;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      c.pause();
    } else if (state == AppLifecycleState.resumed) {
      _onGateChange();
    }
  }

  @override
  void dispose() {
    widget.playGate?.removeListener(_onGateChange);
    WidgetsBinding.instance.removeObserver(this);
    _ctl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _ctl;
    if (c == null || !c.value.isInitialized) {
      return widget.placeholder ?? const Center(child: CircularProgressIndicator());
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: widget.fit,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      ),
    );
  }
}