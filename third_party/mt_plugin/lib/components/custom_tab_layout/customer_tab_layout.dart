import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:mt_plugin/components/theme/mt_theme.dart';

import 'tab_item.dart';

class CustomerTabLayout extends StatefulWidget {
  final List<TabItem> list;
  final TabController? controller;
  final bool? isScrollable;
  final Color? indicatorColor;
  final double? indicatorWeight;
  final EdgeInsetsGeometry? indicatorPadding;
  final Decoration? indicator;
  final TabBarIndicatorSize? indicatorSize;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry? labelPadding;
  final TextStyle? unselectedLabelStyle;
  final DragStartBehavior? dragStartBehavior;
  final OnTabClickListener onTapListener;
  final Color tabBackground;
  final Widget leftWidget;

  CustomerTabLayout(
      {required this.list,
      this.controller,
      this.isScrollable = false,
      this.indicatorColor,
      this.indicatorWeight = 2.0,
      this.indicatorPadding = EdgeInsets.zero,
      this.indicator,
      this.indicatorSize,
      this.labelColor,
      this.labelStyle,
      this.labelPadding,
      this.unselectedLabelColor,
      this.unselectedLabelStyle,
      this.dragStartBehavior = DragStartBehavior.start,
      required this.onTapListener,
      this.leftWidget = const SizedBox(width: 0, height: 0),
      this.tabBackground = const Color(0x80FFFFFF)});

  @override
  _TabControllerPageState createState() => _TabControllerPageState(
      list: list,
      isScrollable: isScrollable,
      indicatorColor: indicatorColor,
      indicatorWeight: indicatorWeight,
      indicatorPadding: indicatorPadding,
      indicator: indicator,
      indicatorSize: indicatorSize,
      labelColor: labelColor,
      labelStyle: labelStyle,
      labelPadding: labelPadding,
      leftWidget: leftWidget,
      unselectedLabelColor: unselectedLabelColor,
      unselectedLabelStyle: unselectedLabelStyle,
      dragStartBehavior: dragStartBehavior,
      tabBackground: tabBackground,
      onTapListener: onTapListener);
}

class _TabControllerPageState extends State<CustomerTabLayout>
    with SingleTickerProviderStateMixin {
  final List<TabItem> list;
  late TabController controller;
  final bool? isScrollable;
  final Color? indicatorColor;
  final double? indicatorWeight;
  final EdgeInsetsGeometry? indicatorPadding;
  final Decoration? indicator;
  final TabBarIndicatorSize? indicatorSize;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final TextStyle? labelStyle;
  final EdgeInsetsGeometry? labelPadding;
  final TextStyle? unselectedLabelStyle;
  final DragStartBehavior? dragStartBehavior;
  final OnTabClickListener onTapListener;
  final Color tabBackground;
  final Widget leftWidget;

  _TabControllerPageState(
      {required this.list,
      this.isScrollable = false,
      this.indicatorColor,
      this.indicatorWeight = 2.0,
      this.indicatorPadding = EdgeInsets.zero,
      this.indicator,
      this.indicatorSize,
      this.labelColor,
      this.labelStyle,
      this.labelPadding,
      this.unselectedLabelColor,
      this.unselectedLabelStyle,
      this.leftWidget = const SizedBox(width: 0.0, height: 0.0),
      this.dragStartBehavior = DragStartBehavior.start,
      required this.onTapListener,
      required this.tabBackground});

  @override
  void initState() {
    controller = TabController(vsync: this, length: list.length);
    controller.addListener(() {
      print("hsd" + controller.index.toString());
      onTapListener.onTap(controller.index);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          color: tabBackground,
          child: Row(
            children: [
              leftWidget,
              Expanded(flex:1,
                  child: TabBar(
                    controller: controller,
                    indicatorColor: Colors.transparent,
                    indicator: indicator,
                    labelColor: labelColor ?? MtTheme.THEME_COLOR,
                    indicatorSize: indicatorSize ?? TabBarIndicatorSize.label,
                    unselectedLabelColor:
                        unselectedLabelColor ?? Color(0xFFFFFFFF),
                    unselectedLabelStyle: unselectedLabelStyle ??
                        TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    indicatorPadding: indicatorPadding ?? EdgeInsets.zero,
                    dragStartBehavior:
                        dragStartBehavior ?? DragStartBehavior.start,
                    indicatorWeight: indicatorWeight ?? 0,
                    isScrollable: isScrollable ?? false,
                    labelStyle: labelStyle ??
                        TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    tabs: _buildTabsWidget(list),
                  ))

            ],
          ),
        ),
        Divider(height: 0.2),
        Flexible(
          child: TabBarView(
            controller: controller,
            children: _buildContentWidget(list),
          ),
        )
      ],
    );
  }

  List<Widget> _buildTabsWidget(List<TabItem> tabList) {
    var list = <Widget>[];
    for (var i = 0; i < tabList.length; i++) {
      var widget = Tab(text: tabList[i].tabTitle);
      list.add(widget);
    }
    return list;
  }

  List<Widget> _buildContentWidget(List<TabItem> tabList) {
    var list = <Widget>[];
    for (var i = 0; i < tabList.length; i++) {
      var contentWidget = tabList[i].childWidget;
      list.add(contentWidget);
    }
    return list;
  }
}

abstract class OnTabClickListener {
  onTap(int index);
}
