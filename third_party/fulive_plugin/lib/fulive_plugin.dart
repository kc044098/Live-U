
import 'package:flutter/services.dart';

class FaceunityPlugin {
  // 声明 MethodChannel
  static const methodChannel = MethodChannel('fulive_plugin');

  /// 初始化 FaceUnity：指定資源來源子資料夾（例如：'faceunity'）
  /// 搭配方案 A：請先把所有 .bundle / .js 放到 android/app/src/main/assets/faceunity/
  /// 原生側需實作對應的 "initFromAssets" method（我在下方補了 Kotlin 範例）
  static Future<bool> initFromAssets(String subDir) async {
    final ok = await methodChannel.invokeMethod('initFromAssets', {
      "arguments": [
        {"subDir": subDir}
      ]
    });
    return ok == true;
  }

  // 获取平台版本号
  static Future<String?> getPlatformVersion() async {
    try {
      final String? version =
          await methodChannel.invokeMethod<String>('getPlatformVersion');
      return version;
    } on PlatformException {
      return null;
    }
  }

  // 设备是否高端机型
  static Future<int> devicePerformanceLevel() async {
    final int result = await methodChannel.invokeMethod("devicePerformanceLevel");
    return result;
  }

  // 获取模块鉴权码
  static Future<int> getModuleCode(int code) async {
    final int result = await methodChannel.invokeMethod("getModuleCode", {"arguments" : [{"code" : code}]});
    return result;
  }

  /// 设置人脸检测模式
  /// @param mode 0图片 1视频，参考 FURenderKit 相关接口
  static Future<void> setFaceProcessorDetectMode(int mode) async {
     await methodChannel.invokeMethod("setFaceProcessorDetectMode", {"arguments" : [{"mode" : mode}]});
  }

  /// 设置最大人脸数量
  /// @param number 数量，1-4
  static Future<void> setMaxFaceNumber(int number) async {
     await methodChannel.invokeMethod("setMaxFaceNumber", {"arguments" : [{"number" : number}]});
  }
  

  /// 请求原生相册
  /// @param type 类型（0照片 1视频）
  static Future<void> requestAlbumForType(int type) async {
    await methodChannel.invokeMethod("requestAlbumForType", {"arguments" : [{"type" : type}]});
  }

  /// 原生图片和视频选择完成回调，需要原生端调用 MethodChannel("fulive_plugin") 的 invokeMethod 方法
  /// @param callBack 原生端选择完图片和视频并缓存后的回调
  /// @note 原生端选择图片和视频后先自行缓存，Flutter端进入图片或视频渲染后使用
  /// @note 原生端回调结构：method(photoSelected或videoSelected)、arguments(成功true和失败false)
  static Future<void> requestAlbumCallBack(Function callBack) async {
    methodChannel.setMethodCallHandler((call) => callBack(call));
  }

    // 被限制的skin功能
  static Future<List<int>> restrictedSkinParams() async {
    final List<dynamic> result = await methodChannel.invokeMethod("restrictedSkinParams");
    try {
      // Ensure the list contains integers
      final List<int> intList = result.cast<int>();
      return intList;
    } on PlatformException catch (_) {
      return [];
    }
  }
}