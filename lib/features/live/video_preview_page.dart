import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart' as ap;

import 'video_details_page.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class VideoPreviewPage extends StatefulWidget {
  final String videoPath;
  final bool musicAdded;

  const VideoPreviewPage({
    super.key,
    required this.videoPath,
    required this.musicAdded,
  });

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage>
    with RouteAware, WidgetsBindingObserver {
  late VideoPlayerController _videoController;
  ap.AudioPlayer? _audioPlayer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();

    // 延遲播放音樂，避免一開始搶走影片音訊焦點
    Future.delayed(const Duration(milliseconds: 500), () {
      _playMusic();
    });

  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) async {
        if (!mounted || _isDisposed) return;
        setState(() {});

        _videoController.setLooping(false);

        if (_audioPlayer != null) {
          await _audioPlayer!.stop();
          await _audioPlayer!.dispose();
          _audioPlayer = null;
        }

        await _videoController.play();

        _videoController.addListener(() async {
          final value = _videoController.value;
          final pos = value.position;
          final dur = value.duration;

          if (dur != null &&
              pos >= dur &&
              !value.isPlaying &&
              !_isDisposed) {
            await _videoController.seekTo(Duration.zero);

            if (_audioPlayer != null) {
              await _audioPlayer!.stop();
              await _audioPlayer!.dispose();
              _audioPlayer = null;
            }

            await _videoController.play();

            _playMusic();
          }
        });
      });
  }

  Future<void> _playMusic() async {
    if (_isDisposed || !mounted || !widget.musicAdded) return;

    try {
      // 如果之前有音樂，先關掉
      await _audioPlayer?.stop();
      await _audioPlayer?.dispose();
      _audioPlayer = null;

      // 🔐 確保新建後再使用
      final newPlayer = ap.AudioPlayer();

      await newPlayer.setAudioContext(ap.AudioContext(
        android: ap.AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: ap.AndroidContentType.music,
          usageType: ap.AndroidUsageType.media,
          audioFocus: ap.AndroidAudioFocus.none,
        ),
      ));
      await newPlayer.setVolume(0.5);
      await newPlayer.play(ap.AssetSource('demo_music.mp3'));

      _audioPlayer = newPlayer;
    } catch (e) {
      debugPrint('音樂重播失敗: $e');
    }
  }

  void _stopAll({bool disposeController = false}) {
    _videoController.pause();
    if (disposeController) {
      _videoController.dispose();
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
    if (_isDisposed) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _stopAll();
    }

    if (state == AppLifecycleState.resumed) {
      _videoController.play();
      if (widget.musicAdded &&
          (_audioPlayer == null || _audioPlayer?.state != ap.PlayerState.playing)) {
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
        appBar: AppBar(title: const Text('动态預覽')),
        body: Column(
          children: [
            if (_videoController.value.isInitialized)
              Flexible(
                child: AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _stopAll();
                        Navigator.pop(context, false);
                      },
                      child: const Text('重新錄製'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        _stopAll();
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VideoDetailsPage(videoPath: widget.videoPath),
                          ),
                        );

                        if (result == 'resume') {
                          _videoController.play();
                          if (widget.musicAdded) {
                            _playMusic();
                          }
                        }
                      },
                      child: const Text('下一步'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
