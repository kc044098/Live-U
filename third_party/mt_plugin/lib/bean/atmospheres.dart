/// atmospheres : [{"name":"cheer","dir":"cheer","category":"default","thumb":"mt_cheer_icon.png","voiced":false,"downloaded":false},{"name":"gift_box","dir":"gift_box","category":"default","thumb":"mt_gift_box_icon.png","voiced":false,"downloaded":false},{"name":"magic_stick","dir":"magic_stick","category":"default","thumb":"mt_magic_stick_icon.png","voiced":false,"downloaded":false},{"name":"cake","dir":"cake","category":"default","thumb":"mt_cake_icon.png","voiced":false,"downloaded":false},{"name":"lollipop","dir":"lollipop","category":"default","thumb":"mt_lollipop_icon.png","voiced":false,"downloaded":false},{"name":"rocket","dir":"rocket","category":"default","thumb":"mt_rocket_icon.png","voiced":false,"downloaded":false},{"name":"car","dir":"car","category":"default","thumb":"mt_car_icon.png","voiced":false,"downloaded":false},{"name":"balloon","dir":"balloon","category":"default","thumb":"mt_balloon_icon.png","voiced":false,"downloaded":false},{"name":"bixin","dir":"bixin","category":"default","thumb":"mt_bixin_icon.png","voiced":false,"downloaded":false},{"name":"six","dir":"six","category":"default","thumb":"mt_six_icon.png","voiced":false,"downloaded":false}]

class Atmospheres {
  List<Atmosphere>? _atmospheres;

  List<Atmosphere>? get atmospheres => _atmospheres;

  Atmospheres({List<Atmosphere>? atmospheres}) {
    _atmospheres = atmospheres;
  }

  Atmospheres.fromJson(dynamic json) {
    if (json["atmospheres"] != null) {
      _atmospheres = [];
      json["atmospheres"].forEach((v) {
        _atmospheres?.add(Atmosphere.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    if (_atmospheres != null) {
      map["atmospheres"] = _atmospheres?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// name : "cheer"
/// dir : "cheer"
/// category : "default"
/// thumb : "mt_cheer_icon.png"
/// voiced : false
/// downloaded : false

class Atmosphere {
  String? _name;
  String? _dir;
  String? _category;
  String? _thumb;
  bool? _voiced;
  bool? _downloaded;
  bool isSelected = false;

  bool isDownloading = false;

  String? get name => _name;

  String? get dir => _dir;

  String? get category => _category;

  String? get thumb => _thumb;

  bool? get voiced => _voiced;

  bool? get downloaded => _downloaded;

  void setDownloaded(bool hasDownload) {
    _downloaded = hasDownload;
  }

  Atmosphere({String? name,
    String? dir,
    String? category,
    String? thumb,
    bool? voiced,
    bool? downloaded}) {
    _name = name;
    _dir = dir;
    _category = category;
    _thumb = thumb;
    _voiced = voiced;
    _downloaded = downloaded;
  }

  Atmosphere.fromJson(dynamic json) {
    _name = json["name"];
    _dir = json["dir"];
    _category = json["category"];
    _thumb = json["thumb"];
    _voiced = json["voiced"];
    _downloaded = json["downloaded"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["name"] = _name;
    map["dir"] = _dir;
    map["category"] = _category;
    map["thumb"] = _thumb;
    map["voiced"] = _voiced;
    map["downloaded"] = _downloaded;
    return map;
  }
}