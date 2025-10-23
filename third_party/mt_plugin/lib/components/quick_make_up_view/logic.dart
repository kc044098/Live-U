import 'package:get/get.dart';
import 'package:mt_plugin/components/quick_make_up_view/state.dart';
import 'package:mt_plugin/data/mt_cache_utils.dart';
import 'package:mt_plugin/data/mt_parameter.dart';
import 'package:mt_plugin/mt_plugin.dart';


///一键美颜的数据Logic
class QuickMakeUpLogic extends GetxController {
  final QuickMakeUpState state = QuickMakeUpState();

  void clickItem(Rx<QuickMakeUpItem> item) {
    _restoreItemsState(item.value.title);
    int index = 0;
    state.items.forEach((element) {
      if (element.value.title == item.value.title) {
        state.currentIndex(index);
        MtCacheUtils.instance.setQuickBeautifullyPosition(index);
        MtPlugin.setBeautyStyle(
            element.value.type);
        return null;
      } else {
        index++;
      }
    });
  }

  void syncProgressChanged(progress) {
    state.items[state.currentIndex.value].update((val) {
      if (val != null) val.progress = progress.round();
    });
    QuickMakeUpItem item = state.items[state.currentIndex.value].value;
    MtPlugin.setBeautyStyle(item.type);
    MtCacheUtils.instance.setQuickBeautyValue(item.progress);
  }

  ///更新状态
  _restoreItemsState(String title) {
    state.items.forEach((element) {
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
