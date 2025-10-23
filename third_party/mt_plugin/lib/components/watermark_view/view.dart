import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/bean/watermarks.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/components/watermark_view/widget/child_view.dart';
import 'package:mt_plugin/generated/l10n.dart';

import 'logic.dart';

class WaterMarkView extends GetView {
  final logic = Get.put(WaterMarkLogic());

  final state = Get.find<WaterMarkLogic>().state;

  @override
  Widget build(BuildContext context) {
    state.items.clear();
    WaterMarks.watermarks.forEach((element) {
      state.items.add(element.obs);
    });

    return Container(
      height: 225,
      color: MtTheme.DETAIL_PAGE_BACKGROUND_COLOR,
      child: Column(
        children: [
          //对比按钮
          Row(),
          //tabview
          Row(
            children: [
              SizedBox(width: 20, height: 44),
              GestureDetector(
                child: Obx(() => Image.asset(
                    state.canCancel.value
                        ? "mt_icon/icon_none_selected.png"
                        : "mt_icon/icon_none_unselected.png",
                    package: "mt_plugin",
                    width: 19,
                    height: 19)),
                onTap: () => logic.cancelAll(),
              ),
              SizedBox(width: 12),
              Text(
                S.current.watermark,
                style:
                    MtTheme.TAB_TEXT_STYLE.copyWith(color: MtTheme.THEME_COLOR),
              )
            ],
          ),

          Divider(height: 2, color: Colors.grey),

          Expanded(
            flex: 1,
            child: WaterMarkChildView(
                state: state,
                onTap: (item) {
                  logic.clickWater(item);
                }),
          )
        ],
      ),
    );
  }
}
