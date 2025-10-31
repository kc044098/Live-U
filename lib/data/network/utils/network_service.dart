import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

/***REMOVED***REMOVED***REMOVED***REMOVED***REMOVED***REMOVED***REMOVED*****
 * final networkService = NetworkService(
    rtcEngine,
    restoreConfig: const VideoEncoderConfiguration(
    dimensions: VideoDimensions(width: 1280, height: 720),
    frameRate: 30,
    bitrate: 1500,
    ),
    onStageChanged: (s) => print(''),
    );

    // 開
    await networkService.start();

    // 關
    await networkService.stop();
 ***REMOVED***REMOVED***REMOVED***REMOVED***REMOVED***REMOVED***REMOVED*****/

enum _NetStage { normal, Stage1, Stage2, Stage3 }

class NetworkService {
  final RtcEngine _engine;
  Timer? _timer;
  bool _running = false;

  final Duration normalDuration;
  final Duration stage1Duration;
  final Duration stage2Duration;
  final Duration stage3Duration;

  final VideoEncoderConfiguration? restoreConfig;
  void Function(_NetStage stage)? onStageChanged;

  NetworkService(
      this._engine, {
        this.normalDuration = const Duration(seconds: 15),
        this.stage1Duration = const Duration(seconds: 15),
        this.stage2Duration = const Duration(seconds: 8),
        this.stage3Duration = const Duration(seconds: 8),
        this.restoreConfig,
        this.onStageChanged,
      });

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    _runCycle(_NetStage.normal);
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    _timer = null;

    try {
      await _engine.muteLocalAudioStream(false);
      await _engine.muteLocalVideoStream(false);

      if (restoreConfig != null) {
        await _engine.setVideoEncoderConfiguration(restoreConfig!);
      } else {
        await _engine.setVideoEncoderConfiguration(const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 30,
          bitrate: 1500,
        ));
      }
    } catch (_) {}
  }

  void _runCycle(_NetStage stage) {
    if (!_running) return;

    onStageChanged?.call(stage);
    _applyStage(stage);

    Duration wait;
    _NetStage next;
    switch (stage) {
      case _NetStage.normal:
        wait = normalDuration;
        next = _NetStage.Stage1;
        break;
      case _NetStage.Stage1:
        wait = stage1Duration;
        next = _NetStage.Stage2;
        break;
      case _NetStage.Stage2:
        wait = stage2Duration;
        next = _NetStage.Stage3;
        break;
      case _NetStage.Stage3:
        wait = stage3Duration;
        next = _NetStage.normal;
        break;
    }

    _timer = Timer(wait, () {
      if (!_running) return;
      _runCycle(next);
    });
  }

  Future<void> _applyStage(_NetStage stage) async {
    try {
      switch (stage) {
        case _NetStage.normal:
          await _engine.muteLocalAudioStream(false);
          await _engine.muteLocalVideoStream(false);
          await _engine.setVideoEncoderConfiguration(const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 1280, height: 720),
            frameRate: 30,
            bitrate: 1500,
          ));
          break;

        case _NetStage.Stage1:
          await _engine.muteLocalAudioStream(false);
          await _engine.muteLocalVideoStream(false);
          await _engine.setVideoEncoderConfiguration(const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 360, height: 640),
            frameRate: 15,
            bitrate: 400,
          ));
          break;

        case _NetStage.Stage2:
          await _engine.muteLocalAudioStream(true);
          await _engine.muteLocalVideoStream(true);
          break;

        case _NetStage.Stage3:
          await _engine.muteLocalAudioStream(false);
          await _engine.muteLocalVideoStream(false);
          await _engine.setVideoEncoderConfiguration(const VideoEncoderConfiguration(
            dimensions: VideoDimensions(width: 480, height: 848),
            frameRate: 20,
            bitrate: 600,
          ));
          break;
      }
    } catch (_) {}
  }
}
