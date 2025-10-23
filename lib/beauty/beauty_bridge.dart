// lib/beauty_bridge.dart
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class BeautyBridge {
  BeautyBridge(this._engine);

  final RtcEngine _engine;
  static const MethodChannel _beauty = MethodChannel('beauty_plugin');

  bool _listening = false;

  Future<void> bind() async {
    if (_listening) return;
    _beauty.setMethodCallHandler(_onMethodCall);
    _listening = true;
  }

  Future<void> startPush() => _beauty.invokeMethod('startAgoraPush');
  Future<void> stopPush() => _beauty.invokeMethod('stopAgoraPush');

  Future<dynamic> _onMethodCall(MethodCall call) async {
    if (call.method != 'onFrame') return null;

    final args = (call.arguments as Map).cast<String, dynamic>();
    final bytes = args['bytes'] as Uint8List;
    final width = args['width'] as int;
    final height = args['height'] as int;
    final stride = args['stride'] as int; // iOS 传的是 bytesPerRow（BGRA 的每行字节数）

    // 关键：Agora 新版 API 要用命名参数 frame:
    await _engine.getMediaEngine().pushVideoFrame(
      frame: ExternalVideoFrame(
        type: VideoBufferType.videoBufferRawData,
        format: VideoPixelFormat.videoPixelBgra, // 跟原生发送一致：BGRA
        buffer: bytes,           // 原样 Uint8List
        stride: stride,          // 这里就是 bytesPerRow（不是像素宽）
        height: height,
        // 旋转角度可先固定，如果你要做方向自适应，可以让原生把 rotation 一并传上来
        rotation: 90,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    return null;
  }
}
