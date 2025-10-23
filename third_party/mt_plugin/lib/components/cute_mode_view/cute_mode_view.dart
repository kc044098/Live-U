import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:get/get.dart';
import 'package:mt_plugin/components/mt_beauty_panel/state.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';

///AR模式选择
class CuteModeView extends GetView {
  final MtBeautyPanelState state;

  CuteModeView(this.state);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 215,
      decoration: BoxDecoration(
        color: MtTheme.MODE_PAGE_BACKGROUND_COLOR,
      ),
      constraints: BoxConstraints(maxHeight: 400),
      child: new CustomScrollView(
        physics: BouncingScrollPhysics(), //越界弹性
        scrollDirection: Axis.horizontal, //设置为横向滚动
        slivers: [
          new SliverPadding(
              padding: const EdgeInsets.all(20.0),
              sliver: new SliverList(
                delegate: new SliverChildListDelegate(
                  <Widget>[
                    _cuteModeItem("mt_icon/icon_class_sticker.png", STICKERS),
                    Container(width: 20),
                    _cuteModeItem("mt_icon/icon_class_mask.png", MASK),
                    Container(width: 20),
                    // _cuteModeItem(
                    //     "mt_icon/icon_class_gift.png", GIFT),
                    // Container(width: 20),
                    // _cuteModeItem(
                    //     "mt_icon/icon_class_watermark.png", WATERMARK),
                    // Container(width: 20),
                  ],
                ),
              ))
        ],
      ),
    );
  }

  //AR模式选择的Item
  Widget _cuteModeItem(String img, int widget) {
    return GestureDetector(
      onTap: () {
        state.panelState(widget | SHOWED);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        child: Align(
          child: Container(
            width: 94,
            height: 94,
            child: Image.asset(img,
                package: "mt_plugin"),
          ),
        ),
      ),
    );
  }
}
