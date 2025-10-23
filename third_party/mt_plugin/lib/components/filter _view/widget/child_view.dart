import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/data/mt_parameter.dart';
import 'package:mt_plugin/typedef/function.dart';

import '../state.dart';

///对于tab的子页面
class FilterChildView extends GetView {
  final FilterState state;

  //第几个item
  final int index;

  FilterChildView(
      {required this.index, required this.onTap, required this.state});

  final ParamSingleCallback<Rx<FilterItem>> onTap;

  @override
  Widget build(BuildContext context) => Container(
    color: MtTheme.MODE_PAGE_BACKGROUND_COLOR,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          child: Row(
              children: state.items[index]
                  .map((item) => buildItem(item, (data) => onTap(data)))
                  .toList()),
        ),
      );

  ///底部的Item
  Widget buildItem(
          Rx<FilterItem> item, ParamSingleCallback<Rx<FilterItem>> onTap) =>
      Padding(
        padding: EdgeInsets.only(left: 4.5, right: 4.5),
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
                            image: AssetImage(item.value.img,package: "mt_plugin"),
                            fit: BoxFit.cover),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadiusDirectional.circular(6))),
                    padding: EdgeInsets.all(2),
                  ),
                  //选中后的蒙层
                  Obx(() => Container(
                        width: 55,
                        height: 55,
                        padding: EdgeInsets.all(12.0),
                        alignment: Alignment.center,
                        child: item.value.isSelected
                            ? Image.asset(
                                "mt_icon/icon_filter_item_selected.png",package: "mt_plugin")
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
              Obx(() => Text(item.value.title,
                  style: MtTheme.ITEM_TEXT_STYLE.copyWith(
                      color: item.value.isSelected
                          ? MtTheme.THEME_COLOR
                          : MtTheme.DARK_TEXT_COLOR)))
            ],
          ),
        ),
      );
}
