import 'dart:async';
import 'package:flutter/services.dart';

class FuliveResult {
  final bool isVideo;
  final String mediaPath;   // 照片：jpg；影片：mp4
  final String? coverPath;  // 影片封面（可能為 null）

  FuliveResult({required this.isVideo, required this.mediaPath, this.coverPath});

  factory FuliveResult.fromMap(Map<dynamic, dynamic> map) {
    return FuliveResult(
      isVideo: (map['isVideo'] ?? false) as bool,
      mediaPath: (map['mediaPath'] ?? '') as String,
      coverPath: (map['coverPath'] as String?),
    );
  }
}

/// FaceUnity 離線美顏橋接
class FuliveBridge {
  static const MethodChannel _ch = MethodChannel('fulive_plugin');

  /// 開啟 FaceUnity 的美顏相機（由原生顯示 UI、拍攝/錄影，完成後回傳檔案路徑）
  static Future<FuliveResult?> openBeautyCamera({
    required bool videoMode,
  }) async {
    try {
      final res = await _ch.invokeMethod<Map<dynamic, dynamic>>(
        'openBeautyCamera',        // ← 確認原生端 method 名
        <String, dynamic>{'videoMode': videoMode},
      );
      if (res == null) return null;
      return FuliveResult.fromMap(res);
    } on PlatformException catch (e) {
      // 這裡你可以上報/記錄
      return null;
    }
  }

  ///（可選）直接套用濾鏡或美顏參數（若原生支援即時預覽時調參）
  static Future<void> setBeautyParams(Map<String, dynamic> params) async {
    try {
      await _ch.invokeMethod('setBeautyParams', params);  // ← 若原生支援再用
    } catch (_) {}
  }
}
