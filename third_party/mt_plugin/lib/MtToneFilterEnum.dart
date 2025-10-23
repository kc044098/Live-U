///调色滤镜
enum MtToneFilterEnum {
  NO_FILTER, //原图
  LIGHT_EXPOSURE, //轻曝光
  HIGHLIGHT, //高光
  GRAY, //灰调
  AMERICAN, //美式
  BURLY_WOOD, //原木色
  LOW_KEY, //暗调
  LUCENCY, //透明
}

extension MtToneFilterEnumExtension on MtToneFilterEnum {
  String get filterName {
    switch (this) {
      case MtToneFilterEnum.NO_FILTER:
        return "NO_FILTER";
      case MtToneFilterEnum.LIGHT_EXPOSURE:
        return "LIGHT_EXPOSURE";
      case MtToneFilterEnum.HIGHLIGHT:
        return "HIGHLIGHT";
      case MtToneFilterEnum.GRAY:
        return "GRAY";
      case MtToneFilterEnum.AMERICAN:
        return "AMERICAN";
      case MtToneFilterEnum.BURLY_WOOD:
        return "BURLY_WOOD";
      case MtToneFilterEnum.LOW_KEY:
        return "LOW_KEY";
      case MtToneFilterEnum.LUCENCY:
        return "LUCENCY";
    }
  }
}
