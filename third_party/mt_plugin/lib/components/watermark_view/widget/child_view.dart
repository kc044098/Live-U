import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/bean/watermarks.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/typedef/function.dart';

import '../state.dart';


class WaterMarkChildView extends GetView {
  final WaterMarkState state;

  final ParamSingleCallback<Rx<WaterMark>> onTap;

  WaterMarkChildView({required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GridView.count(
          physics: BouncingScrollPhysics(),
          // 定义列数
          crossAxisCount: 5,
          // 定义列边距
          crossAxisSpacing: 20.0,
          // 定义行边距
          mainAxisSpacing: 10.0,
          // 定义内边距
          padding: EdgeInsets.all(10.0),
          // 宽度和高度的比例
          childAspectRatio: 1,
          children: state.items
              .map((item) => _buildWidget(item, (data) => onTap(data)))
              .toList()),
    );
  }

  Widget _buildWidget(
      Rx<WaterMark> item, ParamSingleCallback<Rx<WaterMark>> onTap) {
    return Obx(() => Container(
          height: 200,
          padding: EdgeInsets.all(10.0),
          decoration: BoxDecoration(
              border: Border.all(
                  color: item.value.isSelected
                      ? MtTheme.THEME_COLOR
                      : Colors.transparent,
                  width: item.value.isSelected ? 1 : 0),
              borderRadius: BorderRadius.all(Radius.circular(6.0))),
          child: GestureDetector(
            onTap: () {
              onTap(item);
            },
            child: Image.asset(item.value.thumbId,
                package: "mt_plugin", width: 44),
          ),
        ));
  }
}
