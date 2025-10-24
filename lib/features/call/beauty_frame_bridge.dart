import 'package:djs_live_stream/features/call/rtc_engine_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class BeautyFrameBridge {
  static const _ch = MethodChannel('beauty_plugin'); // ← 跟原生對齊
  static RtcEngineManager? _rtc;

  static void attach(RtcEngineManager rtc) {
    _rtc = rtc;
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'onFrame') {
        final a = Map<dynamic, dynamic>.from(call.arguments);
        final bytes  = a['bytes'] as Uint8List;
        final width  = (a['width'] as num).toInt();
        final height = (a['height'] as num).toInt();
        final strideFromNativeBytes = (a['stride'] as num?)?.toInt(); // 可能是 bytesPerRow
        final rotation = (a['rotation'] as num?)?.toInt() ?? 0;

        // ✅ 正確的長度檢查（BGRA 每像素 4 bytes）
        final expected = width * height * 4;
        if (bytes.length != expected) {
          // 有些原生傳的是 bytesPerRow，幫他換算成「像素」給 Agora
          final strideInPixels = (strideFromNativeBytes != null && strideFromNativeBytes % 4 == 0)
              ? strideFromNativeBytes ~/ 4
              : width; // 退回 width
          // 仍然推，但 log 一下，方便對齊 native
          debugPrint('⚠️ onFrame size=${bytes.length}, expected=$expected, using strideInPixels=$strideInPixels');
          await _rtc?.pushExternalFrame(
            bytes: bytes, width: width, height: height, stride: strideInPixels, rotation: rotation,
          );
          return;
        }

        // Agora 這裡的 stride 傳「像素數」，BGRA 通常就是 width
        await _rtc?.pushExternalFrame(
          bytes: bytes, width: width, height: height, stride: width, rotation: rotation,
        );
      }
    });
  }

  static Future<void> startNativePush() => _ch.invokeMethod('startAgoraPush');
  static Future<void> stopNativePush()  => _ch.invokeMethod('stopAgoraPush');
}
