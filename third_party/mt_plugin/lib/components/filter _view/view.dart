import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/components/custom_tab_layout/customer_tab_layout.dart';
import 'package:mt_plugin/components/custom_tab_layout/tab_item.dart';
import 'package:mt_plugin/components/filter%20_view/state.dart';
import 'package:mt_plugin/components/filter%20_view/widget/child_view.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/data/mt_parameter.dart';
import 'package:mt_plugin/mt_plugin.dart';

import 'logic.dart';

///滤镜View
class FilterView extends GetView implements OnTabClickListener {
  final logic = Get.put(FilterViewLogic());

  final state = Get.find<FilterViewLogic>().state;

  @override
  Widget build(BuildContext context) => Container(
        height: 275,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            //滑动条部分
            Obx(() {
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

              return Opacity(
                opacity: (state.currentTabIndex == 3)
                    ? 1.0
                    : 0,
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "${filterItem.value.progress}",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    new Expanded(
                      flex: 1,
                      //滑动条样式容器
                      child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            overlayColor: Colors.transparent,
                            overlappingShapeStrokeColor: Colors.transparent,
                            trackHeight: 3,
                            thumbColor: Colors.white,
                            valueIndicatorShape:
                                PaddleSliderValueIndicatorShape(),
                          ),
                          //滑动条
                          child: Slider(
                              value: filterItem.value.progress.toDouble(),
                              min: 0,
                              max: 100,
                              label: "${filterItem.value.progress.toString()}",
                              activeColor: MtTheme.THEME_COLOR,
                              inactiveColor: Colors.white,
                              divisions: 1000,
                              semanticFormatterCallback: (newValue) {
                                return "${newValue.round()}";
                              },
                              //滑动条滑动的回调
                              onChanged: (value) {
                                logic.changedProgress(value.round());
                              })),
                    ),
                    Padding(
                        padding: EdgeInsets.all(8),
                        child: Container(
                            //对比
                            child: GestureDetector(
                              onTapDown: (TapDownDetails details) {
                                //按下时关闭渲染
                                MtPlugin.setRenderEnable(false);
                              },
                              onTapUp: (TapUpDetails details) {
                                //抬起时开启渲染
                                MtPlugin.setRenderEnable(true);
                              },
                              child: Image.asset("mt_icon/icon_render.png",
                                  package: "mt_plugin", width: 24),
                            ),
                            width: 24,
                            height: 24))
                  ],
                ),
              );
            }),

            Divider(height: 0.2),

            Expanded(
              flex: 1,
              child: CustomerTabLayout(
                list: [
                  buildTabs(0, state),
                  // buildTabs(1, state),
                  // buildTabs(2, state),
                ],
                isScrollable: true,
                tabBackground: MtTheme.MODE_PAGE_BACKGROUND_COLOR,
                indicator: const BoxDecoration(),
                onTapListener: this,
              ),
            ),
          ],
        ),
      );

  @override
  onTap(int index) {
    //点击顶部tab的回调
    logic.clickTab(state.tabTitles[index].value.tabName);
  }

  TabItem buildTabs(index, FilterState state) {
    return TabItem(
        tabTitle: state.tabTitles[index].value.tabName,
        childWidget: FilterChildView(
          index: index,
          state: state,
          onTap: (item) {
            logic.clickItem(item.value.title);
          },
        ));
  }
}
