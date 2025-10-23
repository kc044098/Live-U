import 'package:get/get.dart';
import 'package:mt_plugin/components/filter%20_view/state.dart';
import 'package:mt_plugin/data/mt_parameter.dart';
import 'package:mt_plugin/mt_plugin.dart';

///滤镜Logic层
class FilterViewLogic extends GetxController {
  final FilterState state = FilterState();

  ///点击子Item的数据处理
  void clickItem(String name) {
    _restoreItemsState(name);
    FilterItem filterItem = getCurrentFilterItem().value;
    if (state.currentTabIndex.value == 0) {
      //选择美颜的原图
      MtPlugin.setBeautyFilterName(filterItem.filterName, filterItem.progress);
      return;
    }

    if (state.currentTabIndex.value == 1) {
      //选择特效滤镜原图
      MtPlugin.setEffectFilterType(filterItem.filterName, filterItem.progress);
      return;
    }

    if (state.currentTabIndex.value == 2) {
      //趣味滤镜
      MtPlugin.setFunnyFilterType(filterItem.filterName);
      return;
    }
  }

  ///点击父tab的数据处理
  void clickTab(String tabName) {
    _restoreTabState(tabName);
  }

  ///进度
  void changedProgress(int progress) {
    Rx<FilterItem> currentFilter = getCurrentFilterItem();

    currentFilter.update((value) {
      value?.progress = progress;
    });

    if (state.currentTabIndex == 0) {
      //当前是风格滤镜的时候
      MtPlugin.setBeautyFilterName(currentFilter.value.filterName, progress);
      return;
    }
    if (state.currentTabIndex == 1) {
      //当前是特效滤镜的时候
      MtPlugin.setEffectFilterType(currentFilter.value.filterName, progress);
      return;
    }
    if (state.currentTabIndex == 2) {
      //当是哈哈镜的时候
      MtPlugin.setFunnyFilterType(currentFilter.value.filterName);
      return;
    }
  }

  void _restoreItemsState(String title) {
    int index = 0;
    bool hasFind = false;

    state.items[state.currentTabIndex.value].forEach((element) {
      if (element.value.title == title) {
        element.update((item) {
          hasFind = true;
          item?.isSelected = true;
        });

        switch (state.currentTabIndex.value) {
          case 0:
            state.currentMeiYanIndex(index);
            break;
          // case 1:
          //   state.currentTeXiaoIndex(index);
          //   break;
          // case 2:
          //   state.currentQuWeiIndex(index);
          //   break;
        }
      } else {
        element.update((item) {
          item?.isSelected = false;
        });
      }
      if (!hasFind) {
        index++;
      }
    });
  }

  void _restoreTabState(String tabName) {
    int index = 0;
    state.tabTitles.forEach((element) {
      if (element.value.tabName == tabName) {
        element.update((val) {
          val?.selected = true;
        });
        state.currentTabIndex(index);
      } else {
        element.update((val) {
          val?.selected = false;
        });
        index++;
      }
    });
  }

  ///获取当前的滤镜单元
  Rx<FilterItem> getCurrentFilterItem() {
    late Rx<FilterItem> filterItem;
    final filters = state.items[state.currentTabIndex.value];
    switch (state.currentTabIndex.value) {
      case 0:
        filterItem = filters[state.currentMeiYanIndex.value];
        break;
      // case 1:
      //   filterItem = filters[state.currentTeXiaoIndex.value];
      //   break;
      // case 2:
      //   filterItem = filters[state.currentQuWeiIndex.value];
      //   break;
    }
    return filterItem;
  }


}
