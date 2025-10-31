///贴纸
class Stickers {
  List<Sticker>? _stickers;

  List<Sticker>? get stickers => _stickers;

  Stickers({List<Sticker>? stickers}) {
    _stickers = stickers;
  }

  Stickers.fromJson(dynamic json) {
    if (json["fb_sticker"] != null) {
      _stickers = [];
      json["fb_sticker"].forEach((v) {
        _stickers?.add(Sticker.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    if (_stickers != null) {
      map["fb_sticker"] = _stickers?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Sticker {
  String? _name;
  String? _dir;
  String? _category;
  String? _thumb;
  bool? _voiced;
  int? _downloaded;
  bool isSelected = false;

  bool isDownloading = false;

  String? get name => _name;

  String? get dir => _dir;

  String? get category => _category;

  String? get thumb => _thumb;

  bool? get voiced => _voiced;

  int? get downloaded => _downloaded;

  Sticker(
      {String? name,
      String? dir,
      String? category,
      String? thumb,
      bool? voiced,
      int? downloaded}) {
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

  Sticker.fromJson(dynamic json) {
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
