import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/components/mt_slider/mt_slider.dart';
import 'package:mt_plugin/components/quick_make_up_view/widget/quick_make_up_items.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/generated/l10n.dart';
import 'package:mt_plugin/mt_plugin.dart';

import 'logic.dart';

///一键美颜的View
class QuickMakeUpView extends GetView<QuickMakeUpView> {
  final logic = Get.put(QuickMakeUpLogic());

  final state = Get.find<QuickMakeUpLogic>().state;

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
          Obx(() => Opacity(
                opacity: state.currentIndex < 0 ? 1.0 : 0,
                child: new Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Obx(() => Text(
                            "${state.items[state.currentIndex.value].value.progress.round()}",
                            style: TextStyle(color: Colors.white),
                          )),
                    ),
                    new Expanded(
                      flex: 1,
                      child: _normalSlider(
                          state.items[state.currentIndex.value].value.progress
                              .toDouble(),
                          (handlerIndex, lowerValue, upperValue) =>
                              {logic.syncProgressChanged(lowerValue.toInt())}),
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
                                  width: 24, package: "mt_plugin"),
                            ),
                            width: 24,
                            height: 24))
                  ],
                ),
              )),
          Divider(height: 0.2, color: MtTheme.DIVIDER_COLOR),
          Container(
            alignment: Alignment.centerLeft,
            color: MtTheme.MODE_PAGE_BACKGROUND_COLOR,
            height: 44,
            child: Padding(
              padding: EdgeInsets.only(left: 28, right: 28),
              child: Text(S.current.quick_beauty,
                  style: MtTheme.TAB_TEXT_STYLE
                      .copyWith(color: MtTheme.THEME_COLOR)),
            ),
          ),
          Divider(height: 0.2, color: MtTheme.DIVIDER_COLOR),
          Expanded(
              child: Container(
            //效果列表
            child: QuickMakeUpItemsView(
              state: state,
              onTap: (item) {
                logic.clickItem(item);
              },
            ),
            alignment: Alignment.center,
            color: MtTheme.DETAIL_PAGE_BACKGROUND_COLOR,//Color.fromARGB(200, 255, 255, 255)
          ))
        ],
      ));
}

//只有正数的滑动条
Widget _normalSlider(
        double value,
        Function(int handlerIndex, dynamic lowerValue, dynamic upperValue)?
            onDragging) =>
    MtSlider(
      values: [value],
      tooltip: FlutterSliderTooltip(
          positionOffset: FlutterSliderTooltipPositionOffset(top: -0),
          format: (value) {
            double value2 = double.parse(value);
            return "${value2.toInt()}%";
          },
          custom: (value) => Container(
                width: 100,
                height: 100,
                child: Center(
                  child: Text("${value.toInt()}%",
                      style: TextStyle(color: Colors.white, fontSize: 24)),
                ),
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("mt_icon/icon_bubble.png",package: "mt_plugin"))),
              )),
      max: 100,
      handlerWidth: 10,
      handlerHeight: 10,
      min: 0,
      handler: FlutterSliderHandler(
          child: new ClipRRect(
        borderRadius: BorderRadius.circular(.5),
        child: Container(
          color: Colors.white,
          width: 1,
          height: 1,
        ),
      )),
      trackBar: FlutterSliderTrackBar(
          activeTrackBar: BoxDecoration(color: MtTheme.THEME_COLOR),
          inactiveTrackBar:
              BoxDecoration(color: MtTheme.SLIDER_BACKGROUND_COLOR)),
      onDragging: onDragging,
    );
