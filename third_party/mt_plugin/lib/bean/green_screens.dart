class GreenScreens {
  List<GreenScreen>? _greenscreens;

  List<GreenScreen>? get greenscreens => _greenscreens;

  GreenScreens({List<GreenScreen>? greenscreens}) {
    _greenscreens = greenscreens;
  }

  GreenScreens.fromJson(dynamic json) {
    if (json['greenscreens'] != null) {
      _greenscreens = [];
      json['greenscreens'].forEach((v) {
        _greenscreens?.add(GreenScreen.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    if (_greenscreens != null) {
      map['greenscreens'] = _greenscreens?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// name : "mt_618"
/// dir : "mt_618"
/// category : "default"
/// thumb : "mt_618_icon.png"
/// voiced : false
/// downloaded : false

class GreenScreen {
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

  GreenScreen(
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

  void setDownload(bool hasDownload) {
    _downloaded = hasDownload;
  }

  GreenScreen.fromJson(dynamic json) {
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
