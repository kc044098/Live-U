import 'package:get/get.dart';
import 'package:mt_plugin/components/meixing_view/state.dart';
import 'package:mt_plugin/components/mt_beauty_panel/state.dart';
import 'package:mt_plugin/data/mt_cache_utils.dart';
import 'package:mt_plugin/data/mt_parameter.dart';

import '../../mt_plugin.dart';

class MeiXingLogic extends GetxController {
  final MeiXingState state = MeiXingState.instance;

  ///点击Item的处理
  void clickItem(Rx<MeiXingItem> item) {
    _restoreItemsState(item.value.title);
    int index = 0;
    state.functionItems.forEach((element) {
      if (element.value.title == item.value.title) {
        state.currentIndex(index);
        MtCacheUtils.instance.setFaceTrimPosition(index);
      } else {
        index++;
      }
    });
  }

  ///点击是否应用的开关
  void clickSwitch() {
    state.isOpen(!state.isOpen.value);
    MtPlugin.setFaceShapeEnable(state.isOpen.value);
  }

  ///更新渲染参数
  void updateRenderValue(int value) {
    state.functionItems[state.currentIndex.value].update((element) {
      element?.progress = value;
      element?.apply();
    });
    MtBeautyPanelState.instance.canClickReset();
  }

  ///更新状态
  _restoreItemsState(String title) {
    state.functionItems.forEach((element) {
      if (element.value.title == title) {
        element.update((item) {
          if (item != null) item.isSelected = true;
        });
      } else {
        element.update((item) {
          if (item != null) item.isSelected = false;
        });
      }
    });
  }
}
