import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/components/mt_beauty_panel/state.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/data/bottom_sheet_mode.dart';


///模式选择页面的布局
class ModeSelectView extends GetView {
  final MtBeautyPanelState state;

  ModeSelectView(this.state, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //获取所有二级页面
    List<BottomSheetMode> modes =
        BottomSheetMode.values.where((element) => element.level == 2).toList();

    return Container(
      height: 215,
      decoration: BoxDecoration(
        color: MtTheme.MODE_PAGE_BACKGROUND_COLOR,
      ),
      constraints: BoxConstraints(maxHeight: 300),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.max,                   // 占满宽度
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 平均分布
          children: modes.map((item) => _imageTopButton(item, state)).toList(),
        ),
      ),
    );

  }
}

///Item
Widget _imageTopButton(BottomSheetMode mode, MtBeautyPanelState state) {
  return Padding(
      padding: const EdgeInsets.only(left: 12, top: 50, bottom: 50, right: 12),
      child: InkWell(
        onTap: () {
          switch (mode) {
            case BottomSheetMode.MODE_MEIYAN:
              state.panelState(MEI_YAN | SHOWED);
              break;
            case BottomSheetMode.MODE_MEIXIN:
              state.panelState(MEI_XIN | SHOWED);
              break;
            case BottomSheetMode.MODE_MENGTU:
              state.panelState(CUTE | SHOWED);
              break;
            case BottomSheetMode.MODE_LVJING:
              state.panelState(FILTER | SHOWED);
              break;
            // case BottomSheetMode.MODE_AUTO:
            //   state.panelState(QUICK_BEAUTY | SHOWED);
            //   break;
          }
        },
        child: Column(
          children: [
            Image.asset(mode.iconAssets,
                package: "mt_plugin",
                height: 40,
                width: 40),
            Container(height: 15.5),
            Text(mode.displayTitle, style: MtTheme.MODE_TEXT_STYLE)
          ],
        ),
      ));
}
