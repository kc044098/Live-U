///魔法滤镜
enum MtMagicFilterEnum {
  NO_FILTER,
  RHYTHM_SPLIT, //律动分屏
  VIRTUAL_MIRROR, //虚拟镜像
  BLACK_WHITE, //黑白电影
  GRID_VIEW, //九宫格
  FOUR_SCREEN, //四屏镜面
  DUMP_BEAT_WAVE, //鼓点波动
  ANGEL_LIGHT, //天使光芒
  COLOR_DANCE, //色彩悦动
  FLASH_BURR, //毛刺闪影
  ILLUSION_VIGNETTE //幻觉晕影
}

extension MtMagicFilterEnumExtension on MtMagicFilterEnum {
  String get filterName {
    switch (this) {
      case MtMagicFilterEnum.NO_FILTER:
        return "NO_FILTER";
      case MtMagicFilterEnum.RHYTHM_SPLIT:
        return "RHYTHM_SPLIT";
      case MtMagicFilterEnum.VIRTUAL_MIRROR:
        return "VIRTUAL_MIRROR";
      case MtMagicFilterEnum.BLACK_WHITE:
        return "BLACK_WHITE";
      case MtMagicFilterEnum.GRID_VIEW:
        return "GRID_VIEW";
      case MtMagicFilterEnum.FOUR_SCREEN:
        return "FOUR_SCREEN";
      case MtMagicFilterEnum.DUMP_BEAT_WAVE:
        return "DUMP_BEAT_WAVE";
      case MtMagicFilterEnum.ANGEL_LIGHT:
        return "ANGEL_LIGHT";
      case MtMagicFilterEnum.COLOR_DANCE:
        return "COLOR_DANCE";
      case MtMagicFilterEnum.FLASH_BURR:
        return "FLASH_BURR";
      case MtMagicFilterEnum.ILLUSION_VIGNETTE:
        return "ILLUSION_VIGNETTE";
    }
  }
}
