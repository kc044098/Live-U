import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/data/mt_parameter.dart';
import 'package:mt_plugin/typedef/function.dart';


import '../state.dart';

///一键美颜下的item是列表
class QuickMakeUpItemsView extends StatelessWidget {
  final QuickMakeUpState state;

  final ParamSingleCallback<Rx<QuickMakeUpItem>> onTap;

  QuickMakeUpItemsView({Key? key, required this.onTap, required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildItemListBg(
            itemBuilder: (item) {
              return ItemWidget(item, (data) => onTap(data));
            },
            state: state),
      ],
    );
  }

  Widget _buildItemListBg(
      {required QuickMakeUpRxFunctionItemBuilder itemBuilder,
        required QuickMakeUpState state}) {
    return Expanded(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(14.0),
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        child: Row(
          children: state.items.map((e) {
            return itemBuilder(e);
          }).toList(),
        ),
      ),
    );
  }

  ///Item
  Widget ItemWidget(Rx<QuickMakeUpItem> item,
      ParamSingleCallback<Rx<QuickMakeUpItem>> onTap) =>
      Padding(
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
              //头图
              Stack(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: ShapeDecoration(
                        image: DecorationImage(
                            image: AssetImage(item.value.iconRes,package: "mt_plugin"),
                            fit: BoxFit.cover),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusDirectional.circular(6))),
                    padding: EdgeInsets.all(2),
                    // child:
                    //     Obx(() => Center(child: Image.asset(item.value.iconRes))),
                  ),
                  //选中后的蒙层
                  Obx(() =>
                      Container(
                        width: 55,
                        height: 55,
                        padding: EdgeInsets.all(12.0),
                        alignment: Alignment.center,
                        child: item.value.isSelected
                            ? Image.asset(
                            "mt_icon/icon_filter_item_selected.png",
                            package: "mt_plugin"
                        )
                            : Container(),
                        decoration: ShapeDecoration(
                            color: item.value.isSelected
                                ? Color(0x70B7AFB2)
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadiusDirectional.circular(6))),
                      ))
                ],
              ),
              SizedBox(height: 8),
              // 文本
              Obx(() =>
                  Text(item.value.title,
                      style: MtTheme.ITEM_TEXT_STYLE.copyWith(
                          color: item.value.isSelected
                              ? MtTheme.THEME_COLOR
                              : MtTheme.DARK_TEXT_COLOR)))
            ],
          ),
        ),
      );
}
