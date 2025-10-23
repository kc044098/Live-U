import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

///资源下载的转圈指示器
class WaitingIndicator extends StatefulWidget {
  final double width;

  final double height;

  const WaitingIndicator({Key? key, required this.width, required this.height})
      : super(key: key);

  @override
  State<WaitingIndicator> createState() =>
      _WaitingIndicatorState(width, height);
}

class _WaitingIndicatorState extends State<WaitingIndicator>
    with TickerProviderStateMixin {
  final double width;

  final double height;

  _WaitingIndicatorState(this.width, this.height);

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Animation<double> animation =
        Tween<double>(begin: 0, end: 2 * pi).animate(_controller);

    return Center(
        child: AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Container(
          width: width,
          height: height,
          child: Transform.rotate(
              angle: animation.value,
              child: Image.asset("mt_icon/icon_loading.png",
                  package: "mt_plugin")),
        );
      },
    ));
  }
}
