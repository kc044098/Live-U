/// portraits : [{"name":"mt_monster","dir":"mt_monster","category":"default","thumb":"mt_monster_icon.png","voiced":false,"downloaded":false},{"name":"mt_cloud","dir":"mt_cloud","category":"default","thumb":"mt_cloud_icon.png","voiced":false,"downloaded":false},{"name":"mt_adoreu","dir":"mt_adoreu","category":"default","thumb":"mt_adoreu_icon.png","voiced":false,"downloaded":false},{"name":"mt_snack","dir":"mt_snack","category":"default","thumb":"mt_snack_icon.png","voiced":false,"downloaded":false},{"name":"mt_star","dir":"mt_star","category":"default","thumb":"mt_star_icon.png","voiced":false,"downloaded":false}]

class Portraits {
  List<Portrait>? _portraits;

  List<Portrait>? get portraits => _portraits;

  Portraits({List<Portrait>? portraits}) {
    _portraits = portraits;
  }

  Portraits.fromJson(dynamic json) {
    if (json['portraits'] != null) {
      _portraits = [];
      json['portraits'].forEach((v) {
        _portraits?.add(Portrait.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    if (_portraits != null) {
      map['portraits'] = _portraits?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// name : "mt_monster"
/// dir : "mt_monster"
/// category : "default"
/// thumb : "mt_monster_icon.png"
/// voiced : false
/// downloaded : false

class Portrait {
  String? _name;
  String? _dir;
  String? _category;
  String? _thumb;
  bool? _voiced;
  bool? _downloaded;
  bool isSelected = false;

  String? get name => _name;

  String? get dir => _dir;

  String? get category => _category;

  String? get thumb => _thumb;

  bool? get voiced => _voiced;

  bool? get downloaded => _downloaded;

  bool downLoading = false;

  Portrait(
      {String? name,
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
  void setDownloaded(bool hasDownload) {
    _downloaded = hasDownload;
  }

  Portrait.fromJson(dynamic json) {
    _name = json['name'];
    _dir = json['dir'];
    _category = json['category'];
    _thumb = json['thumb'];
    _voiced = json['voiced'];
    _downloaded = json['downloaded'];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map['name'] = _name;
    map['dir'] = _dir;
    map['category'] = _category;
    map['thumb'] = _thumb;
    map['voiced'] = _voiced;
    map['downloaded'] = _downloaded;
    return map;
  }
}
