import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/components/portraits_view/widget/child_view.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/file_tools.dart';
import 'package:mt_plugin/generated/l10n.dart';

import 'logic.dart';
import 'state.dart';

///抠图面板
class PortraitsView extends StatelessWidget {
  final PortraitsLogic logic = Get.put(PortraitsLogic());
  final PortraitsState state = Get.find<PortraitsLogic>().state;

  @override
  Widget build(BuildContext context) {
    //读取配置文件中的人像抠图
    FileTools.instance.getPortrait().then((value) {
      print("有${value?.length}个人像抠图");
      state.items.clear();
      value?.forEach((element) {
        state.items.add(element.obs);
      });
      //加载完成
      state.hasLoad(true);
    });

    return Container(
      height: 225,
      decoration: BoxDecoration(
        color: MtTheme.DETAIL_PAGE_BACKGROUND_COLOR,
      ),
      child: Obx(() {
        if (state.hasLoad.value) {
          return Column(
            children: [
              //tabview
              Row(
                children: [
                  SizedBox(width: 28, height: 44),
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
                  Text(S.current.portrait,
                      style: MtTheme.TAB_TEXT_STYLE
                          .copyWith(color: MtTheme.THEME_COLOR))
                ],
              ),
              Divider(height: 2, color: Colors.grey),
              //列表
              Expanded(
                flex: 1,
                child: PortraitChildView(
                    state: state,
                    onTap: (data) {
                      logic.clickItem(data);
                    }),
              )
            ],
          );
        } else {
          return Center(
              child: Text("加载配置中....", style: TextStyle(color: Colors.white)));
        }
      }),
    );
  }
}
