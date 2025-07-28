import '../../features/auth/LoginMethod.dart';

class UserModel {
  final String uid;
  String? displayName;
  String? photoURL;
  bool isVip;
  final bool isBroadcaster;

  /// 多登入方式
  final List<LoginMethod> logins;

  /// 其他擴展欄位
  final Map<String, dynamic>? extra;

  UserModel({
    required this.uid,
    this.displayName = '',
    this.photoURL = '',
    this.isVip = false,
    this.isBroadcaster = false,
    this.logins = const [],
    this.extra,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      displayName: json['displayName'],
      photoURL: json['photoURL'],
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
    String? photoURL,
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
