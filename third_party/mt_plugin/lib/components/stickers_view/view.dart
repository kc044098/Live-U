import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/bean/stickers.dart';
import 'package:mt_plugin/components/custom_tab_layout/customer_tab_layout.dart';
import 'package:mt_plugin/components/custom_tab_layout/tab_item.dart';
import 'package:mt_plugin/components/stickers_view/state.dart';
import 'package:mt_plugin/components/stickers_view/widget/child_view.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/file_tools.dart';

import 'logic.dart';

///贴纸View
class StickersView extends GetView implements OnTabClickListener {

  final logic = Get.put(StickersLogic());

  final state = Get.find<StickersLogic>().state;

  @override
  Widget build(BuildContext context) {
    List<Rx<Sticker>> hot = []; //热门
    FileTools.instance.getStickers().then((value) {
      value?.forEach((element) {
        hot.add(element.obs);
      });
      state.items.add(hot);
      state.hasLoad(true);
    });

    return Obx(() {
      if (state.hasLoad.value) {
        return Container(
          height: 225,
          decoration: BoxDecoration(
            color: MtTheme.DETAIL_PAGE_BACKGROUND_COLOR,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                  flex: 1,
                  child: CustomerTabLayout(
                    leftWidget: Padding(
                      padding: EdgeInsets.only(left: 24, right: 12),
                      child: GestureDetector(
                        child: Obx(() => Image.asset(
                            state.canCancel.value
                                ? "mt_icon/icon_none_selected.png"
                                : "mt_icon/icon_none_unselected.png",
                            package: "mt_plugin",
                            width: 19,
                            height: 19)),
                        onTap: () => logic.cancelAll(),
                      ),
                    ),
                    list: [
                      buildTabs(0, state),
                    ],
                    tabBackground: Colors.transparent,
                    unselectedLabelColor: Colors.white,
                    unselectedLabelStyle:
                        MtTheme.TAB_TEXT_STYLE.copyWith(color: Colors.white),
                    onTapListener: this,
                    isScrollable: true,
                    indicator: const BoxDecoration(),
                  ))
            ],
          ),
        );
      } else {
        return Container(
          color: MtTheme.DETAIL_PAGE_BACKGROUND_COLOR,
          height: 225,
          child: Center(
            child: Text("加载配置文件中..."),
          ),
        );
      }
    });
  }

  ///Tab被点击
  @override
  onTap(int index) {}

  TabItem buildTabs(index, StickersState state) {
    return TabItem(
        tabTitle: state.tabTitles[index].value.tabName,
        childWidget: StickersChildView(
          index: index,
          state: state,
          onTap: (item) {
            logic.clickSticker(item);
          },
        ));
  }
}
