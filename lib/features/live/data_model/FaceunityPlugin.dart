// lib/services/faceunity_service.dart
import 'dart:async';
import 'package:flutter/services.dart';

class FaceunityPlugin {
  static const _ch = MethodChannel('fulive_plugin');

  static Future<String?> getPlatformVersion() =>
      _ch.invokeMethod<String>('getPlatformVersion');

  static Future<int> devicePerformanceLevel() =>
      _ch.invokeMethod<int>('devicePerformanceLevel').then((v) => v ?? 0);

  static Future<int> getModuleCode(int code) =>
      _ch.invokeMethod<int>('getModuleCode', {
        'arguments': [
          {'code': code}
        ]
      }).then((v) => v ?? 0);

  static Future<void> setFaceProcessorDetectMode(int mode) =>
      _ch.invokeMethod('setFaceProcessorDetectMode', {
        'arguments': [
          {'mode': mode}
        ]
      });

  static Future<void> setMaxFaceNumber(int number) =>
      _ch.invokeMethod('setMaxFaceNumber', {
        'arguments': [
          {'number': number}
        ]
      });

  static Future<void> requestAlbumForType(int type) =>
      _ch.invokeMethod('requestAlbumForType', {
        'arguments': [
          {'type': type}
        ]
      });

  static void setMethodCallHandler(Future<dynamic> Function(MethodCall call)? h) {
    _ch.setMethodCallHandler(h);
  }

  static Future<List<int>> restrictedSkinParams() async {
    final res = await _ch.invokeMethod<List<dynamic>>('restrictedSkinParams');
    if (res == null) return <int>[];
    return res.map((e) => (e as num).toInt()).toList();
  }
}

class FaceunityService {
  bool _inited = false;
  StreamController<String> _albumEvents = StreamController.broadcast();

  Stream<String> get albumStream => _albumEvents.stream;

  Future<void> init() async {
    if (_inited) return;
    _inited = true;

    // 設定人臉偵測為影片模式 & 最多人臉數
    await FaceunityPlugin.setFaceProcessorDetectMode(1); // 0: image, 1: video
    await FaceunityPlugin.setMaxFaceNumber(4);

    // 監聽原生回調（例如相簿選擇完成）
    FaceunityPlugin.setMethodCallHandler((call) async {
      if (call.method == 'photoSelected') {
        _albumEvents.add('photoSelected:${call.arguments}');
      } else if (call.method == 'videoSelected') {
        _albumEvents.add('videoSelected:${call.arguments}');
      }
      return null;
    });
  }

  Future<int> performanceLevel() => FaceunityPlugin.devicePerformanceLevel();
  Future<List<int>> restrictedSkinParams() => FaceunityPlugin.restrictedSkinParams();

  Future<void> openNativeAlbumForPhoto() =>
      FaceunityPlugin.requestAlbumForType(0);

  Future<void> openNativeAlbumForVideo() =>
      FaceunityPlugin.requestAlbumForType(1);

  void dispose() {
    _albumEvents.close();
    // 不要把 setMethodCallHandler(null) 放這，避免影響全域；如需放，請集中在 App lifecycle 管
  }
}