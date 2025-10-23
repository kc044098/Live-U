///特效滤镜
enum MtEffectFilterEnum {
  NO_FILTER, //原图
  KA_TONG, //卡通
  YOU_HUA, //油画
  SU_MIAO, //素描
  BAN_HUA, //版画
  FU_DIAO, //浮雕
  MA_SAI_KE, //马赛克
  YUN_DON, //运动
  JIAO_PIAN, //胶片
  YUN_YING, //晕影
  LAO_ZHAO_PIAN //老照片
}

extension MtEffectFilterEnumExtension on MtEffectFilterEnum {
  String get filterName {
    switch (this) {
      case MtEffectFilterEnum.NO_FILTER:
        return "NO_FILTER";
      case MtEffectFilterEnum.KA_TONG:
        return "KA_TONG";
      case MtEffectFilterEnum.YOU_HUA:
        return "YOU_HUA";
      case MtEffectFilterEnum.SU_MIAO:
        return "SU_MIAO";
      case MtEffectFilterEnum.BAN_HUA:
        return "BAN_HUA";
      case MtEffectFilterEnum.FU_DIAO:
        return "FU_DIAO";
      case MtEffectFilterEnum.MA_SAI_KE:
        return "MA_SAI_KE";
      case MtEffectFilterEnum.YUN_DON:
        return "YUN_DON";
      case MtEffectFilterEnum.JIAO_PIAN:
        return "JIAO_PIAN";
      case MtEffectFilterEnum.YUN_YING:
        return "YUN_YING";
      case MtEffectFilterEnum.LAO_ZHAO_PIAN:
        return "LAO_ZHAO_PIAN";
    }
  }
}
