

import 'package:shared_preferences/shared_preferences.dart';

import 'mt_cache_key.dart';
import 'mt_parameter.dart';

///缓存工具类
class MtCacheUtils {
  factory MtCacheUtils() => _getInstance();

  SharedPreferences? _prefs;

  static MtCacheUtils? _instance;

  static MtCacheUtils get instance => _getInstance();

  MtCacheUtils._internal() {
    _initSp();
  }

  Future<void> _initSp() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static MtCacheUtils _getInstance() {
    if (_instance == null) {
      _instance = new MtCacheUtils._internal();
    }
    return _instance!;
  }

  ///加载配置信息
  initAllCache() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    //一键美颜
    int quickBeautyPosition = await getQuickBeautyPosition();
    print("quickBeautyPosition：${quickBeautyPosition}");
    MTParameter.instance.quickMakeUpItems[0].isSelected = false;
    MTParameter.instance.quickMakeUpItems[quickBeautyPosition].isSelected =
        true;
    MTParameter.instance.quickMakeUpItems[quickBeautyPosition].progress =
        await getQuickBeautyValue();

    //美颜
    MTParameter.instance.meiYanItems.forEach((element) async {
      element.progress = await getValueWithName(element.title);
    });

    //美型
    MTParameter.instance.meiXingItems.forEach((element) async {
      element.progress = await getValueWithName(element.title);
    });
  }

  /// 清除配置信息
  clearCache() async {
    _prefs?.clear();
  }

  /// 获取选中了哪个一键美颜s
  Future<int> getQuickBeautyPosition() async =>
      _prefs?.getInt(QUICK_BEAUTY_POSITION) ?? 0;

  /// 设置选中了哪个一键美颜
  setQuickBeautifullyPosition(int position) async =>
      _prefs?.setInt(QUICK_BEAUTY_POSITION, position);

  /// 设置一键美颜的参数值
  setQuickBeautyValue(int value) async =>
      _prefs?.setInt(QUICK_BEAUTY_VALUE, value);

  /// 获取一键美颜的参数值
  Future<int> getQuickBeautyValue() async =>
      _prefs?.getInt(QUICK_BEAUTY_VALUE) ?? 0;

  ///获取指定的参数值
  Future<int> getValueWithName(String name) async => _prefs?.getInt(name) ?? 0;

  ///选中了哪个美颜
  Future<int> getBeautyPosition() async => _prefs?.getInt(BEAUTY_POSITION) ?? 0;

  ///更新选中了哪个美颜
  setBeautyPosition(int value) async =>
      _prefs?.setInt(BEAUTY_POSITION, value) ?? 0;

  ///选中了哪个美型
  Future<int> getFaceTrimPosition() async =>
      _prefs?.getInt(FACE_TRIM_POSITION) ?? 0;

  ///更新选中了哪个美型
  setFaceTrimPosition(int value) async =>
      _prefs?.setInt(FACE_TRIM_POSITION, value);

  ///更新指定的参数值
  void setValueWithName(String name, int value) async =>
      _prefs?.setInt(name, value);
}
