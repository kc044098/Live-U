import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/components/atmosphere_view/view.dart';
import 'package:mt_plugin/components/cute_mode_view/cute_mode_view.dart';
import 'package:mt_plugin/components/expressions/view.dart';
import 'package:mt_plugin/components/gift_view/view.dart';
import 'package:mt_plugin/components/filter%20_view/view.dart';
import 'package:mt_plugin/components/green_screen/view.dart';
import 'package:mt_plugin/components/mask_view/view.dart';
import 'package:mt_plugin/components/meixing_view/view.dart';
import 'package:mt_plugin/components/meiyan_view/view.dart';
import 'package:mt_plugin/components/mt_beauty_view/mode_select_view.dart';
import 'package:mt_plugin/components/portraits_view/view.dart';
import 'package:mt_plugin/components/quick_make_up_view/view.dart';
import 'package:mt_plugin/components/stickers_view/view.dart';
import 'package:mt_plugin/components/watermark_view/view.dart';

import '../state.dart';

///美颜调节面板
class MtBeautyPanel extends StatelessWidget {
  final MtBeautyPanelState state;

  MtBeautyPanel(this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Widget childView;

      if ((state.panelState.value & MEI_XIN) != 0) {
        childView = MeiXingView();
      } else if ((state.panelState.value & MEI_YAN) != 0) {
        childView = MeiYanView();
      } else if ((state.panelState.value & CUTE) != 0) {
        childView = CuteModeView(state);
      } else if ((state.panelState.value & GIFT) != 0) {
        childView = GiftView();
      } else if ((state.panelState.value & MASK) != 0) {
        childView = MaskView();
      } else if ((state.panelState.value & QUICK_BEAUTY) != 0) {
        childView = QuickMakeUpView();
      } else if ((state.panelState.value & STICKERS) != 0) {
        childView = StickersView();
      } else if ((state.panelState.value & WATERMARK) != 0) {
        childView = WaterMarkView();
      } else if ((state.panelState.value & FILTER) != 0) {
        childView = FilterView();
      }
      else {
        childView = ModeSelectView(state);
      }

      return Container(
        child: Visibility(
          visible: (state.panelState.value & SHOWED != 0),
          child: childView,
        ),
      );
    });
  }
}


