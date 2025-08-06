import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../../features/auth/LoginMethod.dart';

class UserModel {
  final String uid;
  String? displayName;
  List<String> photoURL;

  /// 取得主要頭像（第一張）
  String get avatarUrl => photoURL.isNotEmpty ? photoURL.first : '';
  bool isVip;
  final bool isBroadcaster;

  /// 取得用戶生活照（不包含頭像）
  List<String> get gallery => photoURL.length > 1 ? photoURL.sublist(1) : [];

  /// 多登入方式
  final List<LoginMethod> logins;

  /// 其他擴展欄位
  final Map<String, dynamic>? extra;

  UserModel({
    required this.uid,
    this.displayName = 'Guest',
    this.photoURL = const [],
    this.isVip = false,
    this.isBroadcaster = false,
    this.logins = const [],
    this.extra,
  });

  /// 取得頭像 ImageProvider
  ImageProvider<Object> get avatarImage {
    if (avatarUrl.isEmpty) {
      return const AssetImage('assets/my_icon_defult.jpeg');
    }

    // URL
    if (avatarUrl.startsWith('http')) {
      return NetworkImage(avatarUrl);
    }

    // Base64
    if (avatarUrl.startsWith('data:image') || avatarUrl.length > 100) {
      try {
        return MemoryImage(base64Decode(avatarUrl));
      } catch (_) {
        return const AssetImage('assets/my_icon_defult.jpeg');
      }
    }

    // 本地檔案
    return FileImage(File(avatarUrl));
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final dynamic photoRaw = json['photoURL'];

    return UserModel(
      uid: json['uid'] ?? '',
      displayName: json['displayName'] ?? 'Guest',
      photoURL: (json['avatar'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      isVip: json['isVip'] ?? false,
      isBroadcaster: json['isBroadcaster'] ?? false,
      logins: (json['logins'] as List? ?? [])
          .map((e) => LoginMethod.fromJson(e))
          .toList(),
      extra: json['extra'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'photoURL': photoURL,
      'isVip': isVip,
      'isBroadcaster': isBroadcaster,
      'logins': logins.map((e) => e.toJson()).toList(),
      'extra': extra,
    };
  }

  UserModel copyWith({
    String? uid,
    String? displayName,
    List<String>? photoURL,
    bool? isVip,
    bool? isBroadcaster,
    List<LoginMethod>? logins,
    Map<String, dynamic>? extra,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isVip: isVip ?? this.isVip,
      isBroadcaster: isBroadcaster ?? this.isBroadcaster,
      logins: logins ?? this.logins,
      extra: extra ?? this.extra,
    );
  }

  /// 快捷方法：取得主登入帳號
  LoginMethod? get primaryLogin {
    if (logins.isEmpty) return null;
    return logins.firstWhere(
          (e) => e.isPrimary,
      orElse: () => logins.first,
    );
  }
}
