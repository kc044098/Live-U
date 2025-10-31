import 'package:get/get.dart';
import 'package:mt_plugin/components/meixing_view/state.dart';
import 'package:mt_plugin/components/meiyan_view/state.dart';
import 'package:mt_plugin/data/mt_cache_utils.dart';

const HIDE = 1; //隐藏 1
const SHOWED = 1 << 1; //显示 10
const MODE_SELECT = 1 << 2; //功能选择
const MEI_YAN = 1 << 3; //美颜
const MEI_XIN = 1 << 4; //美型
const CUTE = 1 << 5; //AR
const QUICK_BEAUTY = 1 << 6; //一键美颜
const FILTER = 1 << 7; //滤镜
const STICKERS = 1 << 8; //贴纸
// const EXPRESSION = 1 << 9; //表情
const GIFT = 1 << 9; //礼物
const MASK = 1 << 10; //面具
const ATMOSPHERE = 1 << 11; //气氛
const WATERMARK = 1 << 12; //水印
const PORTRAIT = 1 << 13; //人像抠图
const GREEN_SCREEN = 1 << 14; //绿幕

class MtBeautyPanelState {
  RxInt panelState = (HIDE | MODE_SELECT).obs;

  RxBool canReset = true.obs;

  static MtBeautyPanelState? _instance;

  MtBeautyPanelState.init() {}

  factory MtBeautyPanelState() => getInstance();

  static MtBeautyPanelState get instance => getInstance();

  static MtBeautyPanelState getInstance() {
    if (_instance != null) return _instance!;
    _instance = MtBeautyPanelState.init();
    return _instance!;
  }

  ///重置所有参数
  resetParam() {
    MtCacheUtils.instance.setBeautyPosition(0);

    MtCacheUtils.instance.setFaceTrimPosition(0);

    //重置美颜参数
    MeiYanState.instance.currentIndex(0);
    MeiYanState.instance.functionItems.forEach((element) {
      element.update((value) {
        value?.progress = 0;
        value?.isSelected = false;
        value?.apply();
      });
    });

    MeiYanState.instance.functionItems[0].update((value) {
      value?.isSelected = true;
    });

    //重置美型参数

    MeiXingState.instance.currentIndex(0);
    MeiXingState.instance.functionItems.forEach((element) {
      element.update((value) {
        value?.progress = 0;
        value?.isSelected = false;
        value?.apply();
      });
    });
    MeiXingState.instance.functionItems[0].update((value) {
      value?.isSelected = true;
    });
    noReset();
  }

  ///允许点击重置
  canClickReset() {
    canReset(true);
  }

  ///不允许点击重置
  noReset() {
    canReset(false);
  }
}
