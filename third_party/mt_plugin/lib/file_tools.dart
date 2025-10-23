import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mt_plugin/bean/expressions.dart';
import 'package:mt_plugin/bean/gifts.dart';
import 'package:mt_plugin/bean/masks.dart';
import 'package:mt_plugin/bean/portraits.dart';
import 'package:mt_plugin/bean/stickers.dart';
import 'package:mt_plugin/bean/watermarks.dart';

import 'bean/atmospheres.dart';
import 'bean/green_screens.dart';

/**
 * 文件流处理工具类
 */
class FileTools {
  String PATH_BASE = "";

  String PATH_STICKER = "";

  String PATH_EXPRESSION = "";

  String PATH_MASK = "";

  String PATH_GIFT = "";

  String PATH_WATERMARK = "";

  String PATH_ATMOSPHERE = "";

  String PATH_PORTRAITS = "";

  String PATH_GREEN_SCREEN = "";

  factory FileTools() => _getInstance();

  static FileTools get instance => _getInstance();

  static FileTools? _instance;

  FileTools.init() {}

  bool initPath(String basePath) {
    //初始化地址
    if (Platform.isAndroid) {
      PATH_BASE = basePath;
      PATH_STICKER =
          "${PATH_BASE}/files/fbeffect/sticker/fb_sticker_config.json";
      PATH_EXPRESSION = "${PATH_BASE}/files/toivan/expression/expression.json";
      // PATH_MASK = "${PATH_BASE}/files/toivan/mask/mask.json";
      PATH_MASK = "${PATH_BASE}/files/fbeffect/mask/fb_mask_config.json";
      PATH_GIFT = "${PATH_BASE}/files/fbeffect/gift/fb_gift_config.json";
      PATH_WATERMARK = "${PATH_BASE}/files/fbeffect/watermark/ht_watermark_config.json";
      PATH_ATMOSPHERE = "${PATH_BASE}/files/toivan/atmosphere/atmosphere.json";
      PATH_PORTRAITS = "${PATH_BASE}/files/toivan/portrait/portrait.json";
      PATH_GREEN_SCREEN =
          "${PATH_BASE}/files/toivan/greenscreen/greenscreen.json";
    } else if (Platform.isIOS) {
      PATH_BASE = basePath;
      print("缓存:IOS");
      if (Directory("${PATH_BASE}/FBEffect/sticker").existsSync()) {
        //不存在目录 则创建
        Directory("${PATH_BASE}/FBEffect/sticker").createSync();
      }
      if (Directory("${PATH_BASE}/FBEffect/watermark").existsSync()) {
        //不存在目录 则创建
        Directory("${PATH_BASE}/FBEffect/watermark").createSync();
      }
      if (Directory("${PATH_BASE}/Toivan/expression").existsSync()) {
        Directory("${PATH_BASE}/Toivan/expression").createSync();
      }
      if (Directory("${PATH_BASE}/FBEffect/mask").existsSync()) {
        Directory("${PATH_BASE}/FBEffect/mask").createSync();
      }
      if (Directory("${PATH_BASE}/FBEffect/gift").existsSync()) {
        Directory("${PATH_BASE}/FBEffect/gift").createSync();
      }
      if (Directory("${PATH_BASE}/Toivan/atmosphere").existsSync()) {
        Directory("${PATH_BASE}/Toivan/atmosphere").createSync();
      }
      if (Directory("${PATH_BASE}/Toivan/portrait").existsSync()) {
        Directory("${PATH_BASE}/Toivan/portrait").createSync();
      }
      if (Directory("${PATH_BASE}/Toivan/greenscreen").existsSync()) {
        Directory("${PATH_BASE}/Toivan/greenscreen").createSync();
      }

      PATH_STICKER = "${PATH_BASE}/FaceBeauty/sticker/fb_sticker_config.json";
      PATH_EXPRESSION = "${PATH_BASE}/Toivan/expression/expression.json";
      PATH_MASK = "${PATH_BASE}/FaceBeauty/mask/fb_mask_config.json";
      PATH_GIFT = "${PATH_BASE}/FBEffect/gift/fb_gift_config.json";
      PATH_WATERMARK = "${PATH_BASE}/FBEffect/watermark/fb_watermark_config.json";
      PATH_ATMOSPHERE = "${PATH_BASE}/Toivan/atmosphere/atmosphere.json";
      PATH_PORTRAITS = "${PATH_BASE}/Toivan/portrait/portrait.json";
      PATH_GREEN_SCREEN = "${PATH_BASE}/Toivan/greenscreen/greenscreen.json";
    }

    //本地文件未就绪则写入
    if (!File(PATH_MASK).existsSync() &&
        !File(PATH_EXPRESSION).existsSync() &&
        !File(PATH_STICKER).existsSync() &&
        !File(PATH_GIFT).existsSync() &&
        !File(PATH_WATERMARK).existsSync() &&
        !File(PATH_ATMOSPHERE).existsSync() &&
        !File(PATH_PORTRAITS).existsSync()) {
      resetFile();
    }

    return true;
  }

  static FileTools _getInstance() {
    if (_instance == null) {
      _instance = FileTools.init();
    }
    return _instance!;
  }

  //重置下载状态
  resetFile() async {
    rootBundle
        .loadString("packages/mt_plugin/assets/atmospheres.json")
        .then((value) {
      _saveValue(PATH_ATMOSPHERE, value);
    });
    rootBundle
        .loadString("packages/mt_plugin/assets/expressions.json")
        .then((value) {
      _saveValue(PATH_EXPRESSION, value);
    });
    rootBundle.loadString("packages/mt_plugin/assets/fb_mask_config.json").then((value) {
      _saveValue(PATH_MASK, value);
    });
    rootBundle
        .loadString("packages/mt_plugin/assets/fb_sticker_config.json")
        .then((value) {
      _saveValue(PATH_STICKER, value);
    });
    rootBundle
        .loadString("packages/mt_plugin/assets/fb_gift_config.json")
        .then((value) {
      _saveValue(PATH_GIFT, value);
    });
    rootBundle
        .loadString("packages/mt_plugin/assets/fb_watermark_config.json")
        .then((value) {
      _saveValue(PATH_WATERMARK, value);
    });
    rootBundle
        .loadString("packages/mt_plugin/assets/portraits.json")
        .then((value) {
      _saveValue(PATH_PORTRAITS, value);
    });
    rootBundle
        .loadString("packages/mt_plugin/assets/greenscreens.json")
        .then((value) {
      _saveValue(PATH_GREEN_SCREEN, value);
    });
  }

  /**
   * 覆盖保存value到本地文件里面
   */
  _saveValue(String path, String value) async {
    print("写入的地址：${path}");
    print("写入json：${value}");
    try {
      File f = new File(path);
      IOSink slink = f.openWrite(mode: FileMode.write);
      slink.write(value);
      slink.close();
    } catch (e) {
      // 写入错误
      print("写入错误：${e}");
    }
  }

  /**
   * 读取json
   */
  Future<String> loadFileString(String path) async {
    File file;
    try {
      file = new File(path);
      print("--------->>从配置文件中读取<<------");
      return file.readAsString();
    } catch (e) {
      await resetFile();
      file = new File(path);
      print("--------->><读取失败，重新载入配置文件<------");
      print("--------->>错误：${e}<<------");
    }
    return file.readAsString();
  }

  /**
   * 获取贴纸列表
   */
  Future<List<Sticker>?> getStickers() async {
    String jsonStr = await loadFileString(PATH_STICKER);
    Stickers stickers = Stickers.fromJson(json.decode(jsonStr));
    return stickers.stickers;
  }

  /**
   * 读取人像抠图列表
   */
  Future<List<Portrait>?> getPortrait() async {
    String jsonStr = await loadFileString(PATH_PORTRAITS);
    Portraits portraits = Portraits.fromJson(json.decode(jsonStr));
    return portraits.portraits;
  }

  /**
   * 保存人像抠图列表
   */
  savePortrait(List<Portrait> list) async {
    Portraits portraits = new Portraits(portraits: list);
    _saveValue(PATH_PORTRAITS, json.encode(portraits));
  }

  /**
   * 保存贴纸列表
   */
  saveStickers(List<Sticker> list) async {
    Stickers stickers = Stickers(stickers: list);
    _saveValue(PATH_STICKER, json.encode(stickers));
  }

  /**
   * 获取气氛列表
   */
  Future<List<Atmosphere>?> getAtmospheres() async {
    String jsonStr = await loadFileString(PATH_ATMOSPHERE);
    print(jsonStr);
    Atmospheres list = Atmospheres.fromJson(json.decode(jsonStr));
    return list.atmospheres;
  }

  /**
   * 保存气氛列表
   */
  void saveAtmosphere(List<Atmosphere> list) async {
    Atmospheres atmospheres = Atmospheres(atmospheres: list);
    await _saveValue(PATH_ATMOSPHERE, json.encode(atmospheres));
  }

  /**
   * 获取面具列表
   */
  Future<List<Mask>?> getMasks() async {
    String jsonStr = await loadFileString(PATH_MASK);
    Masks list = Masks.fromJson(json.decode(jsonStr));
    return list.masks;
  }

  /**
   * 保存面具的配置信息
   */
  saveMask(List<Mask> list) async {
    Masks masks = Masks(masks: list);
    _saveValue(PATH_MASK, json.encode(masks));
  }

  /**
   * 获取礼物列表
   */
  Future<List<Gift>?> getGifts() async {
    String jsonStr = await loadFileString(PATH_GIFT);
    Gifts list = Gifts.fromJson(json.decode(jsonStr));
    return list.gifts;
  }

  /**
   * 保存礼物的配置信息
   */
  saveGift(List<Gift> list) async {
    Gifts gifts = Gifts(gifts: list);
    _saveValue(PATH_MASK, json.encode(gifts));
  }

  /**
   * 获取水印列表
   */
  // Future<List<WaterMark>?> getWaterMarks() async {
  //   String jsonStr = await loadFileString(PATH_WATERMARK);
  //   WaterMarks list = WaterMarks.fromJson(json.decode(jsonStr));
  //   return list.watermarks;
  // }

  /**
   * 保存水印的配置信息
   */
  // saveWaterMark(List<WaterMark> list) async {
  //   WaterMarks watermarks = WaterMarks(watermarks: list);
  //   _saveValue(PATH_WATERMARK, json.encode(watermarks));
  // }

  /**
   * 获取表情列表
   */
  Future<List<Expression>?> getExpressions() async {
    String jsonStr = await loadFileString(PATH_EXPRESSION);
    Expressions list = Expressions.fromJson(json.decode(jsonStr));
    return list.expressions;
  }

  /**
   * 保存表情列表的信息
   */
  void saveExpressions(List<Expression> list) async {
    Expressions expressions = Expressions(expressions: list);
    await _saveValue(PATH_EXPRESSION, json.encode(expressions));
  }

  /**
   * 获取绿幕列表
   */
  Future<List<GreenScreen>?> getGreenScreen() async {
    String jsonStr = await loadFileString(PATH_GREEN_SCREEN);
    GreenScreens greenScreens = GreenScreens.fromJson(json.decode(jsonStr));
    return greenScreens.greenscreens;
  }

  /**
   * 保存绿幕列表
   */
  saveGreenScreen(List<GreenScreen> items) async {
    GreenScreens greenScreens = GreenScreens(greenscreens: items);
    _saveValue(PATH_GREEN_SCREEN, json.encode(greenScreens));
  }

  ///测试用 打印该目录下的所有文件和子文件夹
  void printFiles(String path) {
    try {
      var directory = new Directory(path);
      List<FileSystemEntity> files = directory.listSync();
      for (var f in files) {
        print(f.path);
        var bool = FileSystemEntity.isFileSync(f.path);
        if (!bool) {
          printFiles(f.path);
        }
      }
    } catch (e) {
      print("目录不存在！");
    }
  }
}
