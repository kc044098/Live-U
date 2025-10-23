import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/components/meiyan_view/widget/MeiyanItems.dart';
import 'package:mt_plugin/components/mt_beauty_panel/state.dart';
import 'package:mt_plugin/components/mt_dialog/mt_dialog.dart';
import 'package:mt_plugin/components/mt_slider/mt_slider.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/generated/l10n.dart';
import 'package:mt_plugin/mt_plugin.dart';

import 'logic.dart';

class MeiYanView extends GetView<MeiYanLogic> {
  final logic = Get.put(MeiYanLogic());

  final state = Get.find<MeiYanLogic>().state;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 279.5,
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                  return _normalSlider(
                      state.functionItems[state.currentIndex.value].value
                          .progress
                          .toDouble(), (handlerIndex, lowerValue, upperValue) {
                    logic.updateRenderValue(lowerValue.round());
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
                        child: Image.asset("mt_icon/icon_render.png",
                            package: "mt_plugin", width: 24),
                      ),
                      width: 24,
                      height: 24))
            ],
          ),

          Divider(height: 0.2),

          Expanded(
            flex: 1,
            child: Container(
              color: MtTheme.SECOND_PAGE_BACKGROUND_COLOR,
              child: Column(
                children: [
                  //Tab标题部分
                  Container(
                    alignment: Alignment.centerLeft,
                    height: 44,
                    padding: EdgeInsets.only(left: 28, right: 28),
                    child: Text(S.current.face_beauty,
                        style: MtTheme.TAB_TEXT_STYLE
                            .copyWith(color: MtTheme.THEME_COLOR)),
                  ),

                  Divider(height: .5, color: MtTheme.DIVIDER_COLOR),

                  Expanded(
                    flex: 1,
                    child: Container(
                        alignment: Alignment.center,
                        height: 100,
                        padding: EdgeInsets.only(top: 12, bottom: 12),
                        //下方的功能列表
                        child: MeiYanItemsWidget(
                          state: state,
                          //点击右边的功能Item
                          onTap: (item) {
                            logic.clickItem(item);
                          },
                          //点击左边开关
                          onSwitchTap: () {
                            logic.clickSwitch();
                          },
                        )),
                  ),

                  //底栏
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
                                        : 'mt_icon/icon_reset_unselected.png',
                                    package: "mt_plugin",width: 20,
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
