import 'package:mt_plugin/generated/l10n.dart';

///用于标记底部 bottom_sheet 的页面状态
enum BottomSheetMode {
  MODE_SELECT, //模式选择页面
  MODE_MEIYAN, //美颜（二级页面）
  MODE_MEIXIN, //美型(二级页面)
  MODE_MENGTU, //AR(二级页面)
  MODE_LVJING, //滤镜（二级页面）
  // MODE_AUTO, //一键美颜
  MODE_MENGTU_DETAIL //AR的具体页面(三级页面)
}


extension BottomSheetModeExtension on BottomSheetMode {
  String get displayTitle {
    switch (this) {
      case BottomSheetMode.MODE_SELECT:
        return "模式选择";
      case BottomSheetMode.MODE_MEIYAN:
        return S.current.face_beauty; //美颜
      case BottomSheetMode.MODE_MEIXIN:
        return S.current.face_shape; // 美型
      case BottomSheetMode.MODE_MENGTU:
        return S.current.cute; //AR
      case BottomSheetMode.MODE_LVJING:
        return S.current.filter; //滤镜
      // case BottomSheetMode.MODE_AUTO:
      //   return S.current.quick_beauty; //一键美颜
      case BottomSheetMode.MODE_MENGTU_DETAIL:
        return "AR列表"; //AR列表
    }
  }

  int get level {
    switch (this) {
      case BottomSheetMode.MODE_SELECT:
        return 1;
      case BottomSheetMode.MODE_MEIYAN:
        return 2;
      case BottomSheetMode.MODE_MEIXIN:
        return 2;
      case BottomSheetMode.MODE_MENGTU:
        return 2;
      case BottomSheetMode.MODE_LVJING:
        return 2;
      // case BottomSheetMode.MODE_AUTO:
      //   return 2;
      case BottomSheetMode.MODE_MENGTU_DETAIL:
        return 3;
    }
  }

  ///获取图标
  String get iconAssets {
    switch (this) {
      case BottomSheetMode.MODE_SELECT:
        return "mt_icon/icon_mode_beauty.png";
      case BottomSheetMode.MODE_MEIYAN:
        return "mt_icon/icon_mode_beauty.png";
      case BottomSheetMode.MODE_MEIXIN:
        return "mt_icon/icon_mode_face_trim.png";
      case BottomSheetMode.MODE_MENGTU:
        return "mt_icon/icon_mode_cute.png";
      case BottomSheetMode.MODE_LVJING:
        return "mt_icon/icon_mode_filter.png";
      // case BottomSheetMode.MODE_AUTO:
      //   return "mt_icon/icon_mode_quick_beauty.png";
      case BottomSheetMode.MODE_MENGTU_DETAIL:
        return "";
    }
  }
}
