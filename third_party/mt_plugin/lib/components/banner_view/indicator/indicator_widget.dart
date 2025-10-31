import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../banner_view.dart';
import 'indicator_utils.dart';

///指示器
class IndicatorWidget extends StatelessWidget {
  final IndicatorContainerBuilder? indicatorContainerBuilder;

  //未被选定的指示器(可选)
  final Widget? indicatorNormal;

  //选中的指示器(可选)
  final Widget? indicatorSelected;

  //指示器的margin
  final double? indicatorMargin;

  //尺寸
  final int size;

  //当前
  final int currentIndex;

  IndicatorWidget(this.size,
      {this.currentIndex = 5,
      this.indicatorSelected,
      this.indicatorMargin,
      this.indicatorNormal,
      this.indicatorContainerBuilder});

  @override
  Widget build(BuildContext context) {
    return _renderIndicator(context);
  }

  Widget _renderIndicator(BuildContext context) {
    Widget smallContainer = new Container(
      // color: Colors.purple[100],
      child: new Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: _renderIndicatorTag(),
      ),
    );

    if (this.indicatorContainerBuilder != null) {
      return this.indicatorContainerBuilder!(context, smallContainer);
    }

    return new Align(
      alignment: Alignment.bottomCenter,
      child: new Opacity(
        opacity: 0.9,
        child: new Container(
          height: 40.0,
          padding: new EdgeInsets.symmetric(horizontal: 16.0),
          color: Colors.transparent,
          alignment: Alignment.center,
          child: smallContainer,
        ),
      ),
    );
  }

  ///渲染indicator
  List<Widget> _renderIndicatorTag() {
    List<Widget> indicators = [];
    final int len = this.size;
    //如果用户未传入自定义样式则使用默认indicator构造器
    Widget selected = this.indicatorSelected ??
        IndicatorUtil.generateIndicatorItem(normal: false);
    Widget normal = this.indicatorNormal ??
        IndicatorUtil.generateIndicatorItem(normal: true);

    for (var index = 0; index < len; index++) {
      indicators.add(index == this.currentIndex ? selected : normal);
      if (index != len - 1) {
        indicators.add(new SizedBox(
          width: this.indicatorMargin,
        ));
      }
    }

    return indicators;
  }
}
