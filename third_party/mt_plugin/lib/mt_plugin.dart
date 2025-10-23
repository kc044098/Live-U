import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mt_plugin/MtEffectFilterEnum.dart';
import 'package:mt_plugin/MtFunnyFilterEnum.dart';
import 'package:mt_plugin/MtMagicFilterEnum.dart';
import 'package:mt_plugin/MtToneFilterEnum.dart';
import 'package:mt_plugin/mt_action.dart';

import 'MtQuickBeautyDefault.dart';

///与原生的交互
class MtPlugin {
  static const MethodChannel _channel = const MethodChannel('mt_plugin');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<int?> renderOESTexture(int textId) async {
    return await _channel.invokeMethod(MTAction.SET_WATERMARK_NAME.methodName,
        <String, dynamic>{"textureId": textId});
  }

  ///初始化SDK
  static Future<bool?> initSDK(String key) async {
    final bool? isSuccess = await _channel.invokeMethod(
        MTAction.INIT_SDK.methodName, <String, dynamic>{"key": key});
    return isSuccess;
  }

  ///获取路径参数
  static Future<Map<dynamic, dynamic>> initPath() async {
    final Map<dynamic, dynamic> paths =
        await _channel.invokeMethod(MTAction.INIT_PATH.methodName);
    return paths;
  }

  ///设置渲染的开启&关闭
  static setRenderEnable(bool enable) async {
    print("call.method:" + enable.toString());
    await _channel.invokeMethod(MTAction.SET_RENDER_ENABLE.methodName,
        <String, dynamic>{"enable": enable});
  }

  ///设置单美颜的开关
  static setFaceBeautyEnable(bool enable) async {
    await _channel.invokeMethod(MTAction.SET_FACE_BEAUTY_ENABLE.methodName,
        <String, dynamic>{"enable": enable});
  }

  ///设置美白[0-100]
  static setWhitenessValue(int value) async {
    await _channel.invokeListMethod(MTAction.SET_WHITENESS_VALUE.methodName,
        <String, dynamic>{"value": value});
  }

  ///磨皮[0-100]
  static setBlurrinessValue(int value) async => await _channel.invokeListMethod(
      MTAction.SET_BLURRINESS_VALUE.methodName,
      <String, dynamic>{"value": value});

  ///红润[0-100]
  static setRosinessValue(int value) async => await _channel.invokeListMethod(
      MTAction.SET_ROSINESS_VALUE.methodName,
      <String, dynamic>{"value": value});

  ///清晰[0-100]
  static setClearnessValue(int value) async => await _channel.invokeListMethod(
      MTAction.SET_CLEAR_NESS_VALUE.methodName,
      <String, dynamic>{"value": value});

  ///亮度[0-100]
  static setBrightnessValue(int value) async => await _channel.invokeListMethod(
      MTAction.SET_BRIGHTNESS_VALUE.methodName,
      <String, dynamic>{"value": value});

  ///去黑眼圈[0-100]
  static setUndereyeCirclesValue(int value) async => await _channel.invokeListMethod(
      MTAction.SET_UNDEREYE_CIRCLES_VALUE.methodName,
      <String, dynamic>{"value": value});

  ///去法令纹[0-100]
  static setNasolabialFoldValue(int value) async => await _channel.invokeListMethod(
      MTAction.SET_NASOLABIAL_FOLD_VALUE.methodName,
      <String, dynamic>{"value": value});

  ///美型的开关
  static setFaceShapeEnable(bool isEnable) async =>
      await _channel.invokeMethod(MTAction.SET_FACE_SHAPE_ENABLE.methodName,
          <String, dynamic>{"value": isEnable});

  ///人中
  static setPhiltrumTrimmingValue(int value) async =>
      await _channel.invokeMethod(
          MTAction.SET_PHILTRUM_TRIMMING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///鼻头
  static setNoseApexLesseningValue(int value) async =>
      await _channel.invokeMethod(
          MTAction.SET_NOSE_APEX_LESSENING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///山根
  static setNoseRootEnlargingValue(int value) async =>
      await _channel.invokeMethod(MTAction.SET_NOSE_ROOT_RNLARING.methodName,
          <String, dynamic>{"value": value});

  ///微笑嘴角
  static setMouthSmilingEnlargingValue(int value) async =>
      await _channel.invokeMethod(
          MTAction.SET_MOUTH_SMILING_ENLARGING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///小脸
  static setFaceLesseningValue(int value) async => await _channel.invokeMethod(
      MTAction.SET_FACE_LESSENING_VALUE.methodName,
      <String, dynamic>{"value": value});

  ///短脸
  static setFaceShorteningValue(int value) async => await _channel.invokeMethod(
      MTAction.SET_FACE_SHORTENING_VALUE.methodName,
      <String, dynamic>{"value": value});

  ///小头
  static setHeadLesseningValue(int value) async => await _channel.invokeMethod(
      MTAction.SET_HEAD_LESSENING_VALUE.methodName,
      <String, dynamic>{"value": value});

  ///大眼 [0-100]
  static setEyeEnlargingValue(int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_EYE_ENLARGING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///圆眼 [0-100]
  static setEyeRoundingValue(int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_EYE_ROUNDING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///丰太阳穴
  static setTempleEnlargingValue(int value) async =>
      await _channel.invokeMethod(
          MTAction.SET_TEMPLE_ENLARG_ING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///瘦脸 [0-100]
  static setCheekThinningValue(int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_CHEEK_THINNING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///V脸 [0-100]
  static setCheekVValue(int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_CHEEK_V_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///窄脸 [0-100]
  static setCheekNarrowingValue(int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_CHEEK_NARROWING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///下颌骨
  static setJawboneThinningValue(int value) async =>
      await _channel.invokeMethod(
          MTAction.SET_JAW_BONE_THINNING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///瘦颧骨 【0-100】
  static setCheekBoneThinning(int value) async => await _channel.invokeMethod(
      MTAction.SET_CHEEK_BONE_THINNING.methodName,
      <String, dynamic>{"value": value});

  ///下巴 [-50,50]
  static setChinTrimmingValue(int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_CHIN_TRIMMING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///发际线 [-50,50]
  static setForeheadTrimmingValue(int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_FOREHEAD_TRIMMING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///嘴型 [-50,50]
  static setMouthTrimmingValue(int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_MOUTH_TRIMMING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///瘦鼻 [-50,50]
  static setNoseThinningValue(int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_NOSE_THINNING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///长鼻 [-50,50]
  static setNoseEnlargingValue(int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_NOSE_ENLARGING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///眼间距 [-50,50]
  static setEyeSpacingTrimmingValue(int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_EYE_SPACING_TRIMMING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///眼角倾斜 [-50,50]
  static setEyeCornerTrimmingValue(int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_EYE_CORNER_TRIMMING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///开眼角[0-100]
  static setEyeCornerEnlargingValue(int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_EYE_CORNER_TRIMMING_VALUE.methodName,
          <String, dynamic>{"value": value});

  ///动态
  static setDynamicStickerName(String? name) async =>
      await _channel.invokeListMethod(
          MTAction.SET_DYNAMIC_STICKER_NAME.methodName,
          <String, dynamic>{"name": name});

  ///表情
  static setExpressionRecreationName(String name) async =>
      await _channel.invokeListMethod(
          MTAction.SET_EXPRESSION_RECREATION_NAME.methodName,
          <String, dynamic>{"name": name});

  ///面具
  static setMaskName(String? name) async => await _channel.invokeListMethod(
      MTAction.SET_MASK_NAME.methodName, <String, dynamic>{"name": name});

  ///礼物
  static setGiftName(String? name) async => await _channel.invokeListMethod(
      MTAction.SET_GIFT_NAME.methodName, <String, dynamic>{"name": name});

  ///水印
  static setWaterMarkName(String? name) async => await _channel.invokeListMethod(
      MTAction.SET_WATERMARK_NAME.methodName, <String, dynamic>{"name": name});

  ///绿幕
  static setGreenScreen(String name) async => await _channel.invokeListMethod(
      MTAction.SET_GREEN_SCREEN.methodName, <String, dynamic>{"name": name});

  ///气氛
  static setAtmosphereItemName(String name) async =>
      await _channel.invokeListMethod(
          MTAction.SET_ATMOSPHERE_ITEM_NAME.methodName,
          <String, dynamic>{"name": name});

  //水印
  //水印名称,水印左上角横坐标[0, 100]，水印右上角纵坐标[0, 100],水印横向占据屏幕的比例[0, 100]
  static setWatermarkName(String name, int x, int y, ratio) async {
    await _channel.invokeMethod(
      MTAction.SET_WATER_NAME.methodName,
      {"name": name, "x": x, "y": y, "ratio": ratio},
    );
  }

  ///美颜滤镜
  static setBeautyFilterName(String name, int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_BEAUTY_FILTER_NAME.methodName,
          <String, dynamic>{"name": name, "value": value});

  ///特效滤镜
  // static setEffectFilterType(MtEffectFilterEnum filterEnum, int value) async =>
  //     await _channel.invokeListMethod(
  //         MTAction.SET_EFFECT_FILTER_TYPE.methodName,
  //         {"name": filterEnum.filterName, "progress": value});

  static setEffectFilterType(String name, int value) async =>
      await _channel.invokeListMethod(
          MTAction.SET_EFFECT_FILTER_TYPE.methodName,
          <String, dynamic>{"name": name, "value": value});

  ///趣味滤镜
  // static setFunnyFilterType(MtFunnyFilterEnum filterEnum) async {
  //   await _channel.invokeMethod(MTAction.SET_FUNNY_FILTER_TYPE.methodName,
  //       {"name": filterEnum.filterName});
  // }
  static setFunnyFilterType(String name) async =>
      await _channel.invokeListMethod(
          MTAction.SET_FUNNY_FILTER_TYPE.methodName,
          <String, dynamic>{"name": name});

  ///设置一键美颜
  static setBeautyStyle(
          int type) async =>
      await _channel.invokeMethod(MTAction.SET_BEAUTY_STYLE.methodName,
          // {"style": mtQuickBeautyDefault.filterName});
          <String, dynamic>{"type": type});

  ///设置人像抠图
  static setPortraitName(String name) async => {
        await _channel
            .invokeMethod(MTAction.SET_PORTRAIT_NAME.methodName, {"name": name})
      };
}
