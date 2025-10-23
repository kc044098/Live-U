import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/data/mt_parameter.dart';
import 'package:mt_plugin/generated/l10n.dart';
import 'package:mt_plugin/typedef/function.dart';

import '../state.dart';

///美颜的Items
class MeiYanItemsWidget extends StatelessWidget {
  final MeiYanState state;

  final ParamSingleCallback<Rx<MeiYanItem>> onTap;

  final ParamVoidCallback onSwitchTap;

  MeiYanItemsWidget(
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
          width: 0.2,
          height: 65,
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
      {required MeiYanRxFunctionItemBuilder itemBuilder,
      required MeiYanState state}) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: state.functionItems.map((e) {
            return itemBuilder(e);
          }).toList(),
        ),
      ),
    );
  }

  Widget buildStateItem(ParamVoidCallback onSwitchTap, MeiYanState state) {
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
          //美颜开、美颜关 文本
          Obx(() => Text(
              state.isOpen.value ? S.current.beauty_on : S.current.beauty_off,
              style: TextStyle(
                  color:
                      state.isOpen.value ? MtTheme.THEME_COLOR : Colors.white,
                  fontSize: 11)))
        ],
      ),
    );
  }

  Widget ItemWidget(
      Rx<MeiYanItem> item, ParamSingleCallback<Rx<MeiYanItem>> onTap) {
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
                          ? Image.asset(item.value.SelectedImageRes,
                              package: "mt_plugin")
                          : Image.asset(item.value.normalImageRes,
                              package: "mt_plugin"),
                    )),
              ),
              SizedBox(height: 8),
              Obx(() => Text(item.value.title,
                  style: MtTheme.ITEM_TEXT_STYLE.copyWith(
                    color: item.value.isSelected
                        ? MtTheme.THEME_COLOR
                        : Colors.white,
                  )))
            ],
          ),
        ));
  }
}
