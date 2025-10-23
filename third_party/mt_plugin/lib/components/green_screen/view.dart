import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/components/green_screen/widget/child_view.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/generated/l10n.dart';

import '../../file_tools.dart';
import 'logic.dart';
import 'state.dart';

class GreenScreenView extends StatefulWidget {
  @override
  _GreenScreenViewState createState() => _GreenScreenViewState();
}

class _GreenScreenViewState extends State<GreenScreenView> {
  final GreenScreenLogic logic = Get.put(GreenScreenLogic());
  final GreenScreenState state = Get.find<GreenScreenLogic>().state;

  @override
  Widget build(BuildContext context) {
    //读取配置文件中的绿幕配置
    FileTools.instance.getGreenScreen().then((value) {
      print("有${value?.length}个绿幕配置");
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

                  ///取消按钮
                  GestureDetector(
                    onTap: () => logic.cancelAll(),
                    child: Obx(() => Image.asset(
                        state.canCancel.value
                            ? "mt_icon/icon_none_selected.png"
                            : "mt_icon/icon_none_unselected.png",
                        package: "mt_plugin",
                        width: 19,
                        height: 19)),
                  ),

                  SizedBox(width: 12),
                  Text(S.current.green_screen,
                      style: MtTheme.TAB_TEXT_STYLE
                          .copyWith(color: MtTheme.THEME_COLOR))
                ],
              ),
              Divider(height: 2, color: Colors.grey),
              //列表
              Expanded(
                flex: 1,
                child: GreenScreenChildView(
                    state: state,
                    onTap: (data) {
                      logic.clickItem(data);
                    }),
              )
            ],
          );
        } else {
          return Center(child: Text("加载配置中...."));
        }
      }),
    );
  }

  @override
  void dispose() {
    Get.delete<GreenScreenLogic>();
    super.dispose();
  }
}
