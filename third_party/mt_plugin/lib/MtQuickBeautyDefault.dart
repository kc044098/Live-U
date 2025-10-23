enum MtQuickBeautyDefault {
  STANDARD_DEFAULT, //标准
  LOLITA_DEFAULT, //萝莉
  GODDESS_DEFAULT, //女神
  CELEBRITY_DEFAULT, //网红
  NATURAL_DEFAULT, //自然
  MILK_DEFAULT, //奶杏
  CARMEL_DEFAULT, //卡梅尔
  PAINTING_DEFAULT, //油画
  NECTARINE_DEFAULT, //蜜桃
  HOLIDAY_DEFAULT, //假日
  LOW_END_DEFAULT, //低端机适配
}

extension MtQuickBeautyDefaultExtension on MtQuickBeautyDefault {
  int get filterName {
    switch (this) {
      case MtQuickBeautyDefault.STANDARD_DEFAULT:
        // return "STANDARD";
        return 0;
      case MtQuickBeautyDefault.LOLITA_DEFAULT:
        // return "LOLITA";
        return 1;
      case MtQuickBeautyDefault.GODDESS_DEFAULT:
        // return "GODDESS";
        return 2;
      case MtQuickBeautyDefault.CELEBRITY_DEFAULT:
        // return "CELEBRITY";
        return 3;
      case MtQuickBeautyDefault.NATURAL_DEFAULT:
        // return "NATURAL";
        return 4;
      case MtQuickBeautyDefault.MILK_DEFAULT:
        // return "MILK";
        return 5;
      case MtQuickBeautyDefault.CARMEL_DEFAULT:
        // return "CARMEL";
        return 6;
      case MtQuickBeautyDefault.PAINTING_DEFAULT:
        // return "PAINTING";
        return 7;
      case MtQuickBeautyDefault.NECTARINE_DEFAULT:
        // return "NECTARINE";
        return 8;
      case MtQuickBeautyDefault.HOLIDAY_DEFAULT:
        // return "HOLIDAY";
        return 9;
      case MtQuickBeautyDefault.LOW_END_DEFAULT:
        // return "LOW_END";
        return 10;
    }
  }
}
