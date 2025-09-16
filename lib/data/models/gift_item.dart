import 'package:meta/meta.dart';
import 'package:flutter/foundation.dart';

@immutable
class GiftItemModel {
  final int id;
  final String title;
  final String icon; // 相對或絕對路徑
  final String url;  // SVGA 檔
  final int gold;
  final int flag;
  final int sort;
  final int isLike;   // 0/1
  final int isQuick;  // 0/1
  final DateTime? updateAt;
  final DateTime? createAt;

  const GiftItemModel({
    required this.id,
    required this.title,
    required this.icon,
    required this.url,
    required this.gold,
    required this.flag,
    required this.sort,
    required this.isLike,
    required this.isQuick,
    this.updateAt,
    this.createAt,
  });

  factory GiftItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? _toDT(dynamic v) {
      if (v == null) return null;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v * 1000);
      if (v is String) {
        final n = int.tryParse(v);
        if (n != null) return DateTime.fromMillisecondsSinceEpoch(n * 1000);
      }
      return null;
    }

    return GiftItemModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      url: json['url'] as String? ?? '',
      gold: json['gold'] as int? ?? 0,
      flag: json['flag'] as int? ?? 0,
      sort: json['sort'] as int? ?? 0,
      isLike: json['is_like'] as int? ?? 0,
      isQuick: json['is_quick'] as int? ?? 0,
      updateAt: _toDT(json['update_at']),
      createAt: _toDT(json['create_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'icon': icon,
    'url': url,
    'gold': gold,
    'flag': flag,
    'sort': sort,
    'is_like': isLike,
    'is_quick': isQuick,
    'update_at': updateAt?.millisecondsSinceEpoch,
    'create_at': createAt?.millisecondsSinceEpoch,
  };
}
