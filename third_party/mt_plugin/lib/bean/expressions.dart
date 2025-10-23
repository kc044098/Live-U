/// expressions : [{"name":"carrot_rabbit","dir":"carrot_rabbit","category":"default","thumb":"mt_carrot_rabbit_icon.png","voiced":false,"downloaded":false,"hint":"试试挑挑眉"},{"name":"twinkle_cat_ears","dir":"twinkle_cat_ears","category":"default","thumb":"mt_twinkle_cat_ears_icon.png","voiced":false,"downloaded":false,"hint":"试试张张嘴"},{"name":"little_devil","dir":"little_devil","category":"default","thumb":"mt_little_devil_icon.png","voiced":false,"downloaded":false,"hint":"试试张张嘴"},{"name":"orange_ears","dir":"orange_ears","category":"default","thumb":"mt_orange_ears_icon.png","voiced":false,"downloaded":false,"hint":"试试挑挑眉"},{"name":"pearl_milk_tea","dir":"pearl_milk_tea","category":"default","thumb":"mt_pearl_milk_tea_icon.png","voiced":false,"downloaded":false,"hint":"试试张张嘴"},{"name":"daji","dir":"daji","category":"default","thumb":"mt_daji_icon.png","voiced":false,"downloaded":false,"hint":"试试眨眨眼"},{"name":"comic_face","dir":"comic_face","category":"default","thumb":"mt_comic_face_icon.png","voiced":false,"downloaded":false,"hint":"试试眨眨眼"},{"name":"masque","dir":"masque","category":"default","thumb":"mt_masque_icon.png","voiced":false,"downloaded":false,"hint":"试试眨眨眼"},{"name":"xiaoying","dir":"xiaoying","category":"default","thumb":"mt_xiaoying_icon.png","voiced":false,"downloaded":false,"hint":"试试眨眨眼"},{"name":"dasheng","dir":"dasheng","category":"default","thumb":"mt_dasheng_icon.png","voiced":false,"downloaded":false,"hint":"试试挑挑眉"}]

class Expressions {
  List<Expression>? _expressions;

  List<Expression>? get expressions => _expressions;

  Expressions({List<Expression>? expressions}) {
    _expressions = expressions;
  }

  Expressions.fromJson(dynamic json) {
    if (json["expressions"] != null) {
      _expressions = [];
      json["expressions"].forEach((v) {
        _expressions?.add(Expression.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    if (_expressions != null) {
      map["expressions"] = _expressions?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

/// name : "carrot_rabbit"
/// dir : "carrot_rabbit"
/// category : "default"
/// thumb : "mt_carrot_rabbit_icon.png"
/// voiced : false
/// downloaded : false
/// hint : "试试挑挑眉"

class Expression {
  String? _name;
  String? _dir;
  String? _category;
  String? _thumb;
  bool? _voiced;
  bool? _downloaded;
  String? _hint;
  bool isSelected = false;
  bool isDownloading = false;

  String? get name => _name;

  String? get dir => _dir;

  String? get category => _category;

  String? get thumb => _thumb;

  bool? get voiced => _voiced;

  bool? get downloaded => _downloaded;

  String? get hint => _hint;

  void setDownload(bool hasDownload) {
    _downloaded = hasDownload;
  }

  Expression({String? name,
    String? dir,
    String? category,
    String? thumb,
    bool? voiced,
    bool? downloaded,
    String? hint}) {
    _name = name;
    _dir = dir;
    _category = category;
    _thumb = thumb;
    _voiced = voiced;
    _downloaded = downloaded;
    _hint = hint;
  }

  Expression.fromJson(dynamic json) {
    _name = json["name"];
    _dir = json["dir"];
    _category = json["category"];
    _thumb = json["thumb"];
    _voiced = json["voiced"];
    _downloaded = json["downloaded"];
    _hint = json["hint"];
  }

  Map<String, dynamic> toJson() {
    var map = <String, dynamic>{};
    map["name"] = _name;
    map["dir"] = _dir;
    map["category"] = _category;
    map["thumb"] = _thumb;
    map["voiced"] = _voiced;
    map["downloaded"] = _downloaded;
    map["hint"] = _hint;
    return map;
  }
}
