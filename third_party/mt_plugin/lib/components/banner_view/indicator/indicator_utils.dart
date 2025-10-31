import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

///指示器工具类
class IndicatorUtil {
  static Widget generateIndicatorItem(
      {bool normal = true, double indicatorSize = 8.0}) {
    return new Container(
      width: normal ? indicatorSize : 3 * indicatorSize,
      height: indicatorSize,
      decoration: new BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(4.0)),
        shape: BoxShape.rectangle,
        color: Colors.white,
      ),
    );
  }
}
