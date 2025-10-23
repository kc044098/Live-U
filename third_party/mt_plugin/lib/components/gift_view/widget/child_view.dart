import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/bean/gifts.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';
import 'package:mt_plugin/components/waiting_indicator/waiting_indicator.dart';
import 'package:mt_plugin/typedef/function.dart';

import '../../../app_config.dart';
import '../state.dart';

class GiftChildView extends GetView {
  final ParamSingleCallback<Rx<Gift>> onTap;

  final GiftState state;

  GiftChildView({required this.onTap, required this.state});

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

  Widget _buildWidget(Rx<Gift> item, ParamSingleCallback<Rx<Gift>> onTap) {
    return Container(
      height: 200,
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
                              width: item.value.isSelected ? 1 : 0),
                          borderRadius: BorderRadius.all(Radius.circular(6.0))),
                      child: CachedNetworkImage(
                        width: 44,
                        height: 44,
                        imageUrl: "${AppConfig.MT_URL}gift/${item.value.thumb}",
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    )),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Obx(() {
                    if (item.value.downloaded == 0) {
                      return Image.asset("mt_icon/icon_download.png",
                          width: 20, package: "mt_plugin");
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
}
