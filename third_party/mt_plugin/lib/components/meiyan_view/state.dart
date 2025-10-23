import 'package:flutter/widgets.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:mt_plugin/data/mt_cache_utils.dart';
import 'package:mt_plugin/data/mt_parameter.dart';

typedef MeiYanFunctionItemBuilder = List<Widget> Function(MeiYanItem item);
typedef MeiYanRxFunctionItemBuilder = Widget Function(Rx<MeiYanItem> item);

class MeiYanState {
  ///底部功能组的数据源
  late List<Rx<MeiYanItem>> functionItems;

  late Rx<int> currentIndex = 0.obs;

  late Rx<bool> isOpen = RxBool(true);

  MeiYanState.init() {
    functionItems =
        MTParameter.instance.meiYanItems.map((element) => element.obs).toList();
    MtCacheUtils.instance.getBeautyPosition().then((value) {
      currentIndex(value);
      functionItems[value].update((val) {
        val?.isSelected = true;
      });
    });
  }

  static MeiYanState? _instance;

  static MeiYanState getInstance() {
    if (_instance != null) return _instance!;
    _instance = MeiYanState.init();
    return _instance!;
  }

  factory MeiYanState() => getInstance();

  static MeiYanState get instance => getInstance();
}
