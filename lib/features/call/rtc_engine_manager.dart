import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

// rtc_engine_manager.dart
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class RtcEngineManager {
  static final RtcEngineManager _i = RtcEngineManager._();
  RtcEngineManager._();
  factory RtcEngineManager() => _i;

  late final RtcEngine _engine;
  bool _inited = false;
  bool _joining = false;

  final ValueNotifier<bool> joined = ValueNotifier(false);
  final ValueNotifier<List<int>> remoteUids = ValueNotifier(<int>[]);
  final ValueNotifier<ConnectionStateType?> connState =
  ValueNotifier<ConnectionStateType?>(null);
  final StreamController<(ErrorCodeType code, String msg)> errors =
  StreamController<(ErrorCodeType, String)>.broadcast();

  ClientRoleType _role = ClientRoleType.clientRoleAudience;
  bool _isVoice = false;
  ChannelProfileType _profile = ChannelProfileType.channelProfileCommunication;

  bool get isInited => _inited;
  bool get isJoined => joined.value;
  RtcEngine get engine => _engine;

  /// 初始化 Agora
  Future<void> init({
    required String appId,
    String? logPath,
    LogLevel logLevel = LogLevel.logLevelInfo,
  }) async {
    if (_inited) return;

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));

    if (logPath != null) {
      await _engine.setLogFile(logPath);
      await _engine.setLogFileSize(10 * 1024);
    }
    await _engine.setLogLevel(logLevel);

    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection c, int elapsed) async {
        joined.value = true;
        _joining = false;

        // ✅ Broadcaster 成功入房後預覽自定義視訊源（美顏後）
        if (_role == ClientRoleType.clientRoleBroadcaster && !_isVoice) {
          try {
            await _engine.startPreview(
              sourceType: VideoSourceType.videoSourceCustom,
            );
          } catch (e) {
            debugPrint('[RTC] startPreview error: $e');
          }
        }
      },
      onLeaveChannel: (RtcConnection c, RtcStats s) {
        joined.value = false;
        _joining = false;
        remoteUids.value = <int>[];
      },
      onUserJoined: (RtcConnection c, int uid, int elapsed) {
        final list = List<int>.from(remoteUids.value);
        if (!list.contains(uid)) list.add(uid);
        remoteUids.value = list;
      },
      onUserOffline: (RtcConnection c, int uid, UserOfflineReasonType reason) {
        final list = List<int>.from(remoteUids.value)..remove(uid);
        remoteUids.value = list;
      },
      onConnectionStateChanged:
          (RtcConnection c, ConnectionStateType s, ConnectionChangedReasonType r) {
        connState.value = s;
      },
      onError: (ErrorCodeType code, String msg) {
        errors.add((code, msg));
      },
    ));

    _inited = true;
  }

  /// 加入頻道（使用自定義視訊源）
  Future<void> join({
    required String channelId,
    required int uid,
    required String token,
    ChannelProfileType profile = ChannelProfileType.channelProfileLiveBroadcasting,
    ClientRoleType role = ClientRoleType.clientRoleBroadcaster,
    bool isVoice = false,
    bool useCustomSource = false,
  }) async {
    if (!_inited) throw StateError('RtcEngineManager not initialized.');
    if (_joining || joined.value) {
      await safeLeave();
    }

    _profile = profile;
    _role = role;
    _isVoice = isVoice;

    await _engine.setChannelProfile(profile);
    await _engine.setClientRole(role: role);
    await _engine.enableAudio();

    if (isVoice) {
      await _engine.disableVideo();
    } else {
      await _engine.enableVideo();
      if (useCustomSource) {
        await _engine.getMediaEngine().setExternalVideoSource(enabled: true, useTexture: false);
      } else {
        await _engine.getMediaEngine().setExternalVideoSource(enabled: false, useTexture: false);
      }
    }

    _joining = true;
    await _engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: ChannelMediaOptions(
        channelProfile: profile,
        clientRoleType: role,
        publishCameraTrack: !isVoice && !useCustomSource,  // ← 內建相機
        publishCustomVideoTrack: !isVoice && useCustomSource, // ← 自定義源
        publishMicrophoneTrack: role == ClientRoleType.clientRoleBroadcaster,
        autoSubscribeVideo: !isVoice,
        autoSubscribeAudio: true,
      ),
    );
  }

  Future<void> safeLeave() async {
    if (!_inited) return;
    if (!joined.value && !_joining) return;
    try {
      await _engine.leaveChannel();
    } catch (_) {}
    joined.value = false;
    _joining = false;
    remoteUids.value = <int>[];
    try {
      await _engine.stopPreview(sourceType: VideoSourceType.videoSourceCustom);
    } catch (_) {}
  }

  Future<void> dispose() async {
    if (!_inited) return;
    try {
      await safeLeave();
      await _engine.release();
    } catch (_) {}
    _inited = false;
  }

  /// 接收原生美顏後的幀並推給 Agora
  Future<void> pushExternalFrame({
    required Uint8List bytes,
    required int width,
    required int height,
    required int stride,
    int rotation = 0,
  }) async {
    if (!_inited) return;
    await _engine.getMediaEngine().pushVideoFrame(
      frame: ExternalVideoFrame(
        type: VideoBufferType.videoBufferRawData,
        format: VideoPixelFormat.videoPixelBgra,
        buffer: bytes,
        stride: stride,
        height: height,
        rotation: rotation,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<String> prepareRtcLogPath() async {
    final dir = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    final path = p.join(dir!.path, 'agorasdk.log');
    final f = File(path);
    if (!(await f.exists())) await f.create(recursive: true);
    return path;
  }
}
