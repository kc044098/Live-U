import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:mt_plugin/components/meiyan_view/state.dart';
import 'package:mt_plugin/components/mt_beauty_panel/state.dart';
import 'package:mt_plugin/data/mt_cache_utils.dart';
import 'package:mt_plugin/data/mt_parameter.dart';
import 'package:mt_plugin/mt_plugin.dart';


///美颜界面的数据持有
class MeiYanLogic extends GetxController {
  final MeiYanState state = MeiYanState.getInstance();

  void clickItem(Rx<MeiYanItem> item) {
    _restoreItemsState(item.value.title);
  }

  void clickSwitch() {
    state.isOpen(!state.isOpen.value);
    MtPlugin.setFaceBeautyEnable(state.isOpen.value);
  }

  ///更新渲染参数
  void updateRenderValue(int value) {
    state.functionItems[state.currentIndex.value].update((val) {
      val?.progress = value;
      val?.apply();
    });
    //允许重置
    MtBeautyPanelState.instance.canClickReset();
  }

  ///更新状态
  _restoreItemsState(String title) {
    int index = 0;
    state.functionItems.forEach((element) {
      if (element.value.title == title) {
        state.currentIndex(index);
        MtCacheUtils.instance.setBeautyPosition(index);
        element.update((item) {
          if (item != null) item.isSelected = true;
        });
      } else {
        index++;
        element.update((item) {
          if (item != null) item.isSelected = false;
        });
      }
    });
  }
}
