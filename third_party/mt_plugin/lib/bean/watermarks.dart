
class WaterMarks {
  WaterMarks._();

  static List<WaterMark> watermarks = [
    new WaterMark("ht_watermark_effect_hongtu", 5, 5, 20, "mt_icon/ht_watermark_effect_hongtu_icon.png"),
    new WaterMark("ht_watermark_effect_manchang", 80, 5, 20, "mt_icon/ht_watermark_effect_manchang_icon.png"),
    new WaterMark("ht_watermark_effect_life", 5, 80, 20, "mt_icon/ht_watermark_effect_life_icon.png"),
    new WaterMark("ht_watermark_effect_diary", 80, 80, 20, "mt_icon/ht_watermark_effect_diary_icon.png"),
  ];
}

class WaterMark {
  String name;
  int x;
  int y;
  int ratio;
  String thumbId;
  bool isSelected = false;

  WaterMark(this.name, this.x, this.y, this.ratio, this.thumbId);
}
