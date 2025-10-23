import 'package:flutter/cupertino.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:mt_plugin/data/mt_cache_utils.dart';
import 'package:mt_plugin/data/mt_parameter.dart';


typedef MeiXingFunctionItemBuilder = List<Widget> Function(MeiXingItem item);
typedef MeiXingRxFunctionItemBuilder = Widget Function(Rx<MeiXingItem> item);

///美型 页面的状态
class MeiXingState {
  ///底部功能组的数据源
  late List<Rx<MeiXingItem>> functionItems;

  late Rx<int> currentIndex = 0.obs;

  late Rx<bool> isOpen = RxBool(true);

  MeiXingState.init() {
    functionItems =
        MTParameter.instance.meiXingItems.map((e) => e.obs).toList();
    MtCacheUtils.instance.getFaceTrimPosition().then((value) {
      currentIndex(value);
      functionItems[value].update((val) {
        val?.isSelected = true;
      });
    });
  }

  static MeiXingState? _instance;

  static MeiXingState getInstance() {
    if (_instance != null) return _instance!;
    _instance = MeiXingState.init();
    return _instance!;
  }

  factory MeiXingState() => getInstance();

  static MeiXingState get instance => getInstance();
}
