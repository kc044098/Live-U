import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/data/mt_cache_utils.dart';
import 'package:mt_plugin/data/mt_parameter.dart';


typedef QuickMakeUpRxFunctionItemBuilder = Widget Function(
    Rx<QuickMakeUpItem> item);

///一键美颜的页面状态
class QuickMakeUpState {
  late List<Rx<QuickMakeUpItem>> items;

  late Rx<int> currentIndex = 0.obs;

  QuickMakeUpState() {
    items = MTParameter.instance.quickMakeUpItems.map((e) => e.obs).toList();
    MtCacheUtils.instance.getQuickBeautyPosition().then((value) {
      currentIndex(value);
    });
  }
}

