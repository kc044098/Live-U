import 'package:flutter/material.dart';

///控制view的显示和不显示的View
class VisibleWidget extends StatefulWidget {
  late final Widget child;

  late final bool visible;

  VisibleWidget({required this.child, required this.visible});

  @override
  _VisibleWidgetState createState() => _VisibleWidgetState(visible);
}

class _VisibleWidgetState extends State<VisibleWidget>
    with TickerProviderStateMixin {
  bool visible;

  _VisibleWidgetState(this.visible);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 300),
      opacity: visible ? 1.0 : 0.0,
      child: new Container(
        child: widget.child,
      ),
    );
  }
}
