import 'package:flutter/cupertino.dart';

abstract class CameraRecorderController {
  Future<void> init();
  Future<void> dispose();
  Future<void> startPreview();
  Future<void> stopPreview();
  Future<void> switchCamera();
  Future<void> setBeauty(Map<String, double> options);

  // 錄影 / 截圖
  Future<void> startRecord();
  Future<String?> stopRecord();             // 回傳檔案路徑
  Future<String?> takePhoto();              // 回傳圖片路徑

  // 產出可放進 UI 的預覽 Widget
  Widget buildPreview();
}
