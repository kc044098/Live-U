/// masks : [{"name":"masquerade1","dir":"masquerade1","thumb":"mt_masquerade1_icon.png","downloaded":false},{"name":"masquerade2","dir":"masquerade2","thumb":"mt_masquerade2_icon.png","downloaded":false},{"name":"masquerade3","dir":"masquerade3","thumb":"mt_masquerade3_icon.png","downloaded":false},{"name":"masquerade4","dir":"masquerade4","thumb":"mt_masquerade4_icon.png","downloaded":false},{"name":"masquerade5","dir":"masquerade5","thumb":"mt_masquerade5_icon.png","downloaded":false},{"name":"no_face_man","dir":"no_face_man","thumb":"mt_no_face_man_icon.png","downloaded":false},{"name":"fox_mask","dir":"fox_mask","thumb":"mt_fox_mask_icon.png","downloaded":false},{"name":"pattern_mask","dir":"pattern_mask","thumb":"mt_pattern_mask_icon.png","downloaded":false},{"name":"half_pattern","dir":"half_pattern","thumb":"mt_half_pattern_icon.png","downloaded":false},{"name":"pearl_mask","dir":"pearl_mask","thumb":"mt_pearl_mask_icon.png","downloaded":false},{"name":"dog_mask","dir":"dog_mask","thumb":"mt_dog_mask_icon.png","downloaded":false},{"name":"kitty_mask","dir":"kitty_mask","thumb":"mt_kitty_mask_icon.png","downloaded":false}]

class Gifts {
  List<Gift>? _gifts;

  List<Gift>? get gifts => _gifts;

  Gifts({List<Gift>? gifts}) {
    _gifts = gifts;
  }

  Gifts.fromJson(dynamic json) {
    if (json["ht_gift"] != null) {
      _gifts = [];
      json["ht_gift"].forEach((v) {
        _gifts?.add(Gift.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    if (_gifts != null) {
      map["ht_gift"] = _gifts?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// name : "masquerade1"
/// dir : "masquerade1"
/// thumb : "mt_masquerade1_icon.png"
/// downloaded : false

class Gift {
  String? _name;
  String? _dir;
  String? _category;
  String? _thumb;
  bool? _voiced;
  int? _downloaded;
  bool isDownloading = false;
  bool isSelected = false;

  // void setDownload(bool hasDownload) {
  //   _downloaded = hasDownload;
  // }

  String? get name => _name;

  String? get dir => _dir;

  String? get category => _category;

  String? get thumb => _thumb;

  bool? get voiced => _voiced;

  // bool? get downloaded => _downloaded;
  int? get downloaded => _downloaded;

  Gift({String? name, String? dir, String? category, String? thumb, bool? voiced, int? downloaded}) {
    _name = name;
    _dir = dir;
    _category = category;
    _thumb = thumb;
    _voiced = voiced;
    _downloaded = downloaded;
  }

  setDownload(int isDownload) {
    _downloaded = isDownload;
  }

  Gift.fromJson(dynamic json) {
    _name = json["name"];
    _dir = json["dir"];
    _category = json["category"];
    _thumb = json["icon"];
    _voiced = json["voiced"];
    _downloaded = json["download"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["name"] = _name;
    map["dir"] = _dir;
    map["category"] = _category;
    map["thumb"] = _thumb;
    map["voiced"] = _voiced;
    map["download"] = _downloaded;
    return map;
  }
}
