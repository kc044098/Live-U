import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/components/meixing_view/widget/meixingitems.dart';
import 'package:mt_plugin/components/mt_beauty_panel/state.dart';
import 'package:mt_plugin/components/mt_dialog/mt_dialog.dart';
import 'package:mt_plugin/components/mt_slider/mt_slider.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/generated/l10n.dart';
import 'package:mt_plugin/mt_plugin.dart';

import 'logic.dart';

///美型View
class MeiXingView extends GetView<MeiXingLogic> {
  final logic = Get.put(MeiXingLogic());

  final state = Get.find<MeiXingLogic>().state;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 279.5,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          //滑动条部分
          new Row(
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: Obx(() => Text(
                      "${state.functionItems[state.currentIndex.value].value.progress}%",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    )),
              ),
              new Expanded(
                flex: 1,
                //滑动条样式容器
                child: Obx(() {
                  if (state
                      .functionItems[state.currentIndex.value].value.canMinus) {
                    return _canMinusSlider(
                        state.functionItems[state.currentIndex.value].value
                            .progress
                            .toDouble(),
                        (handlerIndex, lowerValue, upperValue) {
                      logic.updateRenderValue(lowerValue.toInt());
                    });
                  }
                  return _normalSlider(
                      state.functionItems[state.currentIndex.value].value
                          .progress
                          .toDouble(),
                          (handlerIndex, lowerValue, upperValue) {
                    logic.updateRenderValue(lowerValue.toInt());
                  });
                }),
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
                        child:
                            Image.asset("mt_icon/icon_render.png",package: "mt_plugin", width: 24),
                      ),
                      width: 24,
                      height: 24))
            ],
          ),

          Divider(height: 0.2),

          Expanded(
            child: Container(
              color: MtTheme.SECOND_PAGE_BACKGROUND_COLOR,
              child: Column(
                children: [
                  //Tab标题部分
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 44,
                    child: Padding(
                      padding: EdgeInsets.only(left: 28, right: 28),
                      child: Text(S.current.face_shape,
                          style: MtTheme.TAB_TEXT_STYLE
                              .copyWith(color: MtTheme.THEME_COLOR)),
                    ),
                  ),
                  Divider(height: 0.3, color: MtTheme.DIVIDER_COLOR),
                  //内容区域
                  Expanded(
                      flex: 1,
                      child: Container(
                          height: 100,
                          alignment: Alignment.center,
                          //下方的功能列表
                          child: MeiXingItemsWidget(
                            state: state,
                            //点击右边的功能Item
                            onTap: (item) {
                              logic.clickItem(item);
                            },
                            //点击左边开关
                            onSwitchTap: () {
                              logic.clickSwitch();
                            },
                          ))),
                  //重置按钮
                  Container(
                    padding: EdgeInsets.only(left: 25, right: 25, bottom: 27.5),
                    height: 55,
                    child: Stack(
                      children: [
                        Positioned(
                          child: GestureDetector(
                            onTap: () {
                              if (MtBeautyPanelState.instance.canReset.value) {
                                MtDialog(
                                    onClickCancel: () {},
                                    onClickOk: () {
                                      MtBeautyPanelState.instance.resetParam();
                                    }).show(context);
                              }
                            },
                            child: Row(
                              children: [
                                Obx(() => Image.asset(
                                    MtBeautyPanelState.instance.canReset.value
                                        ? 'mt_icon/icon_reset_selected.png'
                                        : 'mt_icon/icon_reset_unselected.png',package: "mt_plugin",
                                    width: 20,
                                    height: 20)),
                                SizedBox(width: 1.5),
                                Obx(() => Text(S.current.reset,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: MtBeautyPanelState
                                                    .instance.canReset.value
                                                ? MtTheme.DARK_TEXT_COLOR
                                                : MtTheme.GRAY_TEXT_COLOR))),
                              ],
                            ),
                          ),
                          left: 0,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

//可以负数的滑动条
Widget _canMinusSlider(
        double value,
        Function(int handlerIndex, dynamic lowerValue, dynamic upperValue)?
            onDragging) =>
    MtSlider(
      values: [value],
      tooltip: FlutterSliderTooltip(
          disableAnimation: false,
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
                      style: TextStyle(color: Colors.white,fontSize: 24)),
                ),
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("mt_icon/icon_bubble.png",package: "mt_plugin"))),
              )),
      max: 50,
      handlerWidth: 10,
      handlerHeight: 10,
      centeredOrigin: true,
      min: -50,
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
          centralWidget: Container(height: 15, width: 2, color: Colors.white),
          activeTrackBar: BoxDecoration(color: MtTheme.THEME_COLOR),
          inactiveTrackBar:
              BoxDecoration(color: MtTheme.SLIDER_BACKGROUND_COLOR)),
      onDragging: onDragging,
    );

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
                      style: TextStyle(color: Colors.white,fontSize: 24)),
                ),
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("mt_icon/icon_bubble.png",package: "mt_plugin")
                    )
                ),
              )
      ),
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
