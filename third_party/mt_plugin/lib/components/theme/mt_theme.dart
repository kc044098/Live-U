import 'package:flutter/cupertino.dart';

class MtTheme {
  MtTheme._();

  //主题颜色
  static const Color THEME_COLOR = Color(0xFFAAF208);//0xFFFF77B7

  //分割线的颜色
  static const Color DIVIDER_COLOR = Color(0xFFAEA6A9);

  //深色字颜色
  static const Color DARK_TEXT_COLOR = Color(0xFFFFFFFF);//0xFF433341

  //不启用的字颜色
  static const Color GRAY_TEXT_COLOR = Color(0xFFFFFFFF);//0xFFAEA6A9

  //小控件的底部字体
  static const TextStyle ITEM_TEXT_STYLE = TextStyle(fontSize: 10);

  //Tab的字体
  static const TextStyle TAB_TEXT_STYLE = TextStyle(fontSize: 12);

  //滑动条背景颜色
  static const Color SLIDER_BACKGROUND_COLOR = Color(0xCCFFFFFF);

  //功能选中页面的背景颜色
  static const Color MODE_PAGE_BACKGROUND_COLOR = Color(0xB3000000);//0xCCFFFFFF

  //第二级页面的背景颜色
  static const Color SECOND_PAGE_BACKGROUND_COLOR = Color(0xB3000000);//0xCCFFFFFF

  //细节页面的背景颜色
  static const Color DETAIL_PAGE_BACKGROUND_COLOR = Color(0xB3000000);//0xB33B3B3B

  //功能选择页面的底部字体属性
  static TextStyle MODE_TEXT_STYLE =
      TextStyle(color: Color(0xFFFFFFFF), fontSize: 12);//0xFF433341
}
