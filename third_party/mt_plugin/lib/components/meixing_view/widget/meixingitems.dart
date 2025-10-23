import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/data/mt_parameter.dart';
import 'package:mt_plugin/generated/l10n.dart';
import 'package:mt_plugin/typedef/function.dart';

import '../state.dart';

///美型View组件
class MeiXingItemsWidget extends StatelessWidget {
  final MeiXingState state;

  final ParamSingleCallback<Rx<MeiXingItem>> onTap;

  final ParamVoidCallback onSwitchTap;

  MeiXingItemsWidget(
      {Key? key,
      required this.state,
      required this.onTap,
      required this.onSwitchTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 20),
        //效果开关
        buildStateItem(onSwitchTap, state),
        SizedBox(width: 20),
        //分割线
        Container(
          height: 65,
          width: .2,
          color: MtTheme.DIVIDER_COLOR,
        ),
        //右边列表
        _buildItemListBg(
            itemBuilder: (item) {
              return ItemWidget(item, onTap);
            },
            state: state)
      ],
    );
  }

  Widget _buildItemListBg(
      {required MeiXingRxFunctionItemBuilder itemBuilder,
      required MeiXingState state}) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        child: Row(
          children: state.functionItems.map((e) {
            return itemBuilder(e);
          }).toList(),
        ),
      ),
    );
  }

  Widget buildStateItem(ParamVoidCallback onSwitchTap, MeiXingState state) {
    return GestureDetector(
      onTap: () {
        onSwitchTap();
      },
      child: Column(
        verticalDirection: VerticalDirection.down,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: 50,
              height: 50,
              padding: EdgeInsets.all(10),
              child: Center(
                child: Obx(() => state.isOpen.value
                    ? Image.asset("mt_icon/icon_enable_selected.png",
                        package: "mt_plugin")
                    : Image.asset("mt_icon/icon_enable_unselected.png",
                        package: "mt_plugin")),
              )),
          SizedBox(height: 8),
          //美型 开/关
          Obx(() => Text(
              state.isOpen.value
                  ? S.current.face_trim_on
                  : S.current.face_trim_off,
              style: TextStyle(
                  color:
                      state.isOpen.value ? MtTheme.THEME_COLOR : Colors.white,
                  fontSize: 11)))
        ],
      ),
    );
  }

  Widget ItemWidget(
      Rx<MeiXingItem> item, ParamSingleCallback<Rx<MeiXingItem>> onTap) {
    return Padding(
        padding: EdgeInsets.only(left: 6, right: 6),
        child: GestureDetector(
          onTap: () {
            onTap(item);
          },
          child: Column(
            verticalDirection: VerticalDirection.down,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                padding: EdgeInsets.all(8),
                child: Obx(() => Center(
                      child: item.value.isSelected
                          ? Image.asset(item.value.selectedImageRes,
                              package: "mt_plugin")
                          : Image.asset(item.value.normalImageRes,
                              package: "mt_plugin"),
                    )),
              ),
              SizedBox(height: 6),
              Obx(() => Text(item.value.title,
                  style: MtTheme.ITEM_TEXT_STYLE.copyWith(
                      color: item.value.isSelected
                          ? MtTheme.THEME_COLOR
                          : Color(0xFFFFFFFF))))
            ],
          ),
        ));
  }
}
