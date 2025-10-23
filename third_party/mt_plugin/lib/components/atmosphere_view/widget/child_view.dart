import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/bean/atmospheres.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/components/waiting_indicator/waiting_indicator.dart';
import 'package:mt_plugin/typedef/function.dart';

import '../../../app_config.dart';
import '../state.dart';

/**
 * 气氛的列表
 */
class AtmosphereChildView extends GetView {
  final ParamSingleCallback<Rx<Atmosphere>> onTap;

  final AtmosphereState state;

  AtmosphereChildView({required this.onTap, required this.state});

  Widget _buildWidget(
      Rx<Atmosphere> item, ParamSingleCallback<Rx<Atmosphere>> onTap) {
    return Container(
      child: GestureDetector(
        onTap: () {
          onTap(item);
        },
        child: Obx(() {
          if (item.value.isDownloading) {
            return Center(
              child: WaitingIndicator(width: 44, height: 44),
            );
          } else {
            return Stack(
              children: [
                Positioned(
                    child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: item.value.isSelected
                              ? MtTheme.THEME_COLOR
                              : Colors.transparent,
                          width: item.value.isSelected ? 1 : 0
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(6.0))),
                  child: CachedNetworkImage(
                    imageUrl:
                        "${AppConfig.MT_URL}atmosphere/${item.value.thumb}",
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                )),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Obx(() {
                    if (!item.value.downloaded!) {
                      return Image.asset("mt_icon/icon_download.png",
                          package: "mt_plugin", width: 20);
                    } else {
                      return SizedBox();
                    }
                  }),
                )
              ],
            );
          }
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: GridView.count(
          physics: BouncingScrollPhysics(),
          // 定义列数
          crossAxisCount: 5,
          // 定义列边距
          crossAxisSpacing: 20.0,
          // 定义行边距
          mainAxisSpacing: 20.0,
          // 定义内边距
          padding: EdgeInsets.all(10.0),
          // 宽度和高度的比例
          childAspectRatio: 1,
          children: state.items
              .map((item) => _buildWidget(item, (data) => onTap(data)))
              .toList()),
    );
  }
}
