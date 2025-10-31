///趣味滤镜
enum MtFunnyFilterEnum {
  NO_FILTER, //原图
  ALIEN, //外星人
  BIG_NOSE, //大鼻子
  BIG_MOUTH, //大嘴巴
  SQUARE_FACE, //方形脸
  BIG_HEAD, //大头
  PLUMP_FACE, //嘟嘟脸
  PEAS_EYES, //豆豆眼
  LARGE_FOREHEAD, //大额头
  ARCH_FACE, //弓形脸
  SNAKE_SPIRIT, //蛇精脸
}

extension MtFunnyFilterEnumExtension on MtFunnyFilterEnum {
  String get filterName {
    switch (this) {
      case MtFunnyFilterEnum.NO_FILTER:
        return "NO_FILTER";
      case MtFunnyFilterEnum.ALIEN:
        return "ALIEN";
      case MtFunnyFilterEnum.BIG_NOSE:
        return "BIG_NOSE";
      case MtFunnyFilterEnum.BIG_MOUTH:
        return "BIG_MOUTH";
      case MtFunnyFilterEnum.SQUARE_FACE:
        return "SQUARE_FACE";
      case MtFunnyFilterEnum.BIG_HEAD:
        return "BIG_HEAD";
      case MtFunnyFilterEnum.PLUMP_FACE:
        return "PLUMP_FACE";
      case MtFunnyFilterEnum.PEAS_EYES:
        return "PEAS_EYES";
      case MtFunnyFilterEnum.LARGE_FOREHEAD:
        return "LARGE_FOREHEAD";
      case MtFunnyFilterEnum.ARCH_FACE:
        return "ARCH_FACE";
      case MtFunnyFilterEnum.SNAKE_SPIRIT:
        return "SNAKE_SPIRIT";
    }
  }
}
