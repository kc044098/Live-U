import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../profile/profile_controller.dart';
import 'video_details_page.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class VideoPreviewPage extends ConsumerStatefulWidget {
  final String videoPath;
  final bool musicAdded;
  final String? thumbnailPath;
  final String? musicPath;

  const VideoPreviewPage({super.key,
    required this.videoPath,
    this.thumbnailPath,
    required this.musicAdded,
    this.musicPath,
  });

  @override
  ConsumerState<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends ConsumerState<VideoPreviewPage>
    with RouteAware, WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  ap.AudioPlayer? _audioPlayer;
  bool _isDisposed = false;
  bool _isRestarting = false;
  late final bool _isPhoto;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _isPhoto = widget.videoPath.toLowerCase().endsWith('.jpg') ||
        widget.videoPath.toLowerCase().endsWith('.png');

    if (!_isPhoto) {
      _initializeVideo();
      Future.delayed(const Duration(milliseconds: 500), () => _playMusic());
    }
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) async {
        if (!mounted || _isDisposed) return;
        setState(() {});
        _videoController!.setLooping(false);

        await _videoController!.play();

        _videoController!.addListener(() async {
          final value = _videoController!.value;

          if (_isDisposed || !mounted || value.duration == null) return;

          final isEnded = value.position >= value.duration * 0.99;

          // 播完後延遲1秒再重播
          if (!_isRestarting && isEnded && !value.isPlaying) {
            _isRestarting = true;

            await Future.delayed(const Duration(seconds: 1));
            if (!mounted || _isDisposed) return;

            await _videoController!.seekTo(Duration.zero);
            await _videoController!.play();
            await _playMusic(); // 如果需要重播音樂
            _isRestarting = false;
          }
        });
      });
  }

  Future<void> _playMusic() async {
    if (_isDisposed || !mounted || _isPhoto) return;
    if (!widget.musicAdded || widget.musicPath == null || widget.musicPath!.isEmpty) return;

    try {
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();
      _audioPlayer = ap.AudioPlayer();
      await _audioPlayer?.setAudioContext(ap.AudioContext(
        android: ap.AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: ap.AndroidContentType.music,
          usageType: ap.AndroidUsageType.media,
          audioFocus: ap.AndroidAudioFocus.none,
        ),
      ));
      await _audioPlayer!.setVolume(0.5);

      final url = _absUrl(widget.musicPath!.trim()); // ★ 相對 → 絕對
      await _audioPlayer!.play(ap.UrlSource(url));
    } catch (e) {
      debugPrint('音樂播放失敗: $e');
    }
  }

  String _absUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;

    final profile = ref.read(userProfileProvider);
    final cdn = (profile?.cdnUrl ?? '').trim();

    final p = path.startsWith('/') ? path.substring(1) : path;

    debugPrint('[Preview] build abs url: '
        'cdn="$cdn", rawPath="$p" -> full="$cdn/$p"');
    return '$cdn/$p';
  }

  void _stopAll({bool disposeController = false}) {
    _videoController?.pause();
    if (disposeController) {
      _videoController?.dispose();
    }
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _stopAll(disposeController: true);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || _isPhoto) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _stopAll();
    }

    if (state == AppLifecycleState.resumed) {
      _videoController?.play();
      if (widget.musicAdded &&
          (_audioPlayer == null ||
              _audioPlayer?.state != ap.PlayerState.playing)) {
        _playMusic();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _stopAll();
        Navigator.pop(context, false);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: _isPhoto
                  ? Image.file(
                File(widget.videoPath),
                fit: BoxFit.cover,
              )
                  : (_videoController?.value.isInitialized ?? false
                  ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              )
                  : const Center(child: CircularProgressIndicator())),
            ),

            // 左上角返回
            Positioned(
              top: MediaQuery.of(context).padding.top + 50,
              left: 24,
              child: GestureDetector(
                onTap: () {
                  _stopAll();
                  Navigator.pop(context, false);
                },
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),

            // 底部下一步
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    _stopAll();
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoDetailsPage(
                          videoPath: widget.videoPath,
                          thumbnailPath: widget.thumbnailPath,
                          musicAdded: widget.musicAdded,   // ★ 傳遞音樂開關
                          musicPath: widget.musicPath,     // ★ 傳遞相對路徑（不拼接）
                        ),
                      ),
                    );
                    if (result == 'resume' && !_isPhoto) {
                      _videoController?.play();
                      if (widget.musicAdded) _playMusic();
                    }
                  },
                  child: Container(
                    width: 288,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB56B), Color(0xFFDF65F8)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        S.of(context).nextStep,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
