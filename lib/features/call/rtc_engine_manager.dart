import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

// rtc_engine_manager.dart
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../beauty/beauty_bridge.dart';


class RtcEngineManager {
  static final RtcEngineManager _i = RtcEngineManager._();
  RtcEngineManager._();
  factory RtcEngineManager() => _i;

  late final RtcEngine _engine;
  bool _inited = false;
  bool _joining = false;

  // 當前狀態
  final ValueNotifier<bool> joined = ValueNotifier(false);
  final ValueNotifier<List<int>> remoteUids = ValueNotifier(<int>[]);
  final ValueNotifier<ConnectionStateType?> connState =
  ValueNotifier<ConnectionStateType?>(null);
  final StreamController<(ErrorCodeType code, String msg)> errors =
  StreamController<(ErrorCodeType, String)>.broadcast();

  // 設定記憶
  ClientRoleType _role = ClientRoleType.clientRoleAudience;
  bool _isVoice = false;
  ChannelProfileType _profile = ChannelProfileType.channelProfileCommunication;

  bool get isInited => _inited;
  bool get isJoined => joined.value;
  RtcEngine get engine {
    if (!_inited) {
      throw StateError('RtcEngineManager not initialized. Call init() first.');
    }
    return _engine;
  }

  // RtcEngineManager 内部
  late final BeautyBridge _beauty;   // 新增
  bool _useExternalBeautyCapture = false; // 新增：是否走外部采集

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
      await _engine.setLogFileSize(10 * 1024); // 10MB
    }
    await _engine.setLogLevel(logLevel);

    // 全域事件：把 SDK 回呼轉成 Notifier/Stream
    _engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection c, int elapsed) async {
        joined.value = true;
        _joining = false;

        // 只有 Broadcaster 且「非語音」才需要預覽（join 成功後開）
        if (_role == ClientRoleType.clientRoleBroadcaster && !_isVoice) {
          if (_useExternalBeautyCapture) {
            // 关键：使用自定义视频源的预览
            try {
              await _engine.startPreview(sourceType: VideoSourceType.videoSourceCustom);
            } catch (_) {}
            // 成功入房后，让原生开始把帧回推给 Flutter
            try { await _beauty.startPush(); } catch (_) {}
          } else {
            try { await _engine.startPreview(); } catch (_) {}
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

    _beauty = BeautyBridge(_engine);
    await _beauty.bind();

    _inited = true;
  }

  /// 統一入口：加入房間（可指定 profile/role/語音或視訊）
  Future<void> join({
    required String channelId,
    required int uid,
    required String token,
    ChannelProfileType profile = ChannelProfileType.channelProfileCommunication,
    ClientRoleType role = ClientRoleType.clientRoleBroadcaster,
    bool isVoice = false,
  }) async {
    if (!_inited) throw StateError('RtcEngineManager not initialized.');
    if (_joining || joined.value) {
      // 已在 join 流程中或已加入，先離開再進
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
      // ⚠️ 若使用外部采集，先声明外部视频源，再启用视频
      if (_useExternalBeautyCapture) {
        await _engine.getMediaEngine().setExternalVideoSource(
          enabled: true,
          useTexture: false, // 和范例一致：走 Raw/BGRA
        );
      }
      await _engine.enableVideo();
      // 这里不直接 startPreview；让 onJoinChannelSuccess 选 custom 或默认
    }

    _joining = true;
    await _engine.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: ChannelMediaOptions(
        channelProfile: profile,
        clientRoleType: role,
        publishCameraTrack: role == ClientRoleType.clientRoleBroadcaster && !isVoice,
        publishMicrophoneTrack: role == ClientRoleType.clientRoleBroadcaster,
        autoSubscribeVideo: !isVoice,
        autoSubscribeAudio: true,
      ),
    );
  }

  Future<void> switchToBroadcaster() async {
    if (!_inited) return;
    _role = ClientRoleType.clientRoleBroadcaster;
    await _engine.updateChannelMediaOptions(const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      publishCameraTrack: true,
      publishMicrophoneTrack: true,
    ));
    if (!_isVoice) {
      try { await _engine.startPreview(); } catch (_) {}
    }
  }

  Future<void> switchToAudience() async {
    if (!_inited) return;
    _role = ClientRoleType.clientRoleAudience;
    await _engine.updateChannelMediaOptions(const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleAudience,
      publishCameraTrack: false,
      publishMicrophoneTrack: false,
    ));
    try { await _engine.stopPreview(); } catch (_) {}
  }

  Future<void> safeLeave() async {
    if (!_inited) return;
    if (!joined.value && !_joining) return;
    try { await _engine.leaveChannel(); } catch (_) {}
    joined.value = false;
    _joining = false;
    remoteUids.value = <int>[];
    try { await _beauty.stopPush(); } catch (_) {}
    try { await _engine.stopPreview(); } catch (_) {}
  }

  Future<void> dispose() async {
    if (!_inited) return;
    try { await safeLeave(); } catch (_) {}
    try { await _engine.release(); } catch (_) {}
    _inited = false;
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

  Future<void> enableExternalBeautyCapture(bool enable) async {
    _useExternalBeautyCapture = enable;
  }
}