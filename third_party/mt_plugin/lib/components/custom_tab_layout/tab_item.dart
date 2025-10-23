import 'package:flutter/material.dart';

class TabItem {
  String tabTitle;
  Widget childWidget;

  TabItem({
    required this.tabTitle,
    required this.childWidget});

  @override
  String toString() {
    return 'TabItem{tabTitle: $tabTitle, childWidget: $childWidget}';
  }
}