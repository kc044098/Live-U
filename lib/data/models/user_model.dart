import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:djs_live_stream/data/network/background_api_service.dart';
import 'package:flutter/cupertino.dart';

import '../../features/auth/LoginMethod.dart';

import 'package:flutter/material.dart';

class UserModel {
  final String uid;                  // 用戶ID (id)
  String? displayName;               // 暱稱 (nick_name)
  List<String> photoURL;             // 頭像清單 (avatar)
  List<String> get photoURLAbs =>
      photoURL.where((e) => e.isNotEmpty).map((e) => e.joinCdn(cdnUrl)).toList();

  /// 從頭像列表取得主要頭像
  String get avatarUrl {
    for (final s in photoURL) {
      if (s.isNotEmpty) return s;
    }
    return '';
  }
  String get avatarUrlAbs => avatarUrl.joinCdn(cdnUrl);

  bool isVip;                        // 會員狀態 (vip)
  final bool isBroadcaster;          // 是否為主播 (flag = 2 代表主播)

  /// 多登入方式
  final List<LoginMethod> logins;

  /// 用戶詳細資料(例如身高體重年齡三圍等)
  final Map<String, dynamic>? extra; // detail

  // ==== 後端其他直接對應欄位 ====
  final String? account;
  final String? apple;
  final String? facebook;
  final int? flag;                   // 1=普通用户，2=主播
  final int? gid;                    // 工會ID
  final String? google;              // 谷歌账号
  final String? inviteCode;          // 邀请码
  final int? isTest;                 // 1=內部,2=普通
  final String? loginIp;             // 登录ip
  final String? oAuthId;             // 验证id
  final String? pDirector;           // 所属的工会总监
  final String? pStaff;              // 所属的工会主管
  final String? pSupervisor;         // 所属的工会业务员
  final String? regIp;               // 注册ip
  final String? cdnUrl;              // s3 儲存位置
  final int? sex;                    // 1=男,2=女,3=不願透露,0=未設置
  final int? fans;                   // 粉絲數
  final int? isLike;                 // 是否喜欢:1=喜欢,2=否
  final int? status;                 // 用户状态：1=在线,2=忙碌,3=离线
  final List<String>? tags;          // 標籤
  final String? email;               // 邮箱
  final String? password;            // pwd
  final int? createAt;               // 註冊時間
  final int? loginTime;              // 登錄時間

  UserModel({
    required this.uid,
    this.displayName = 'Guest',
    this.photoURL = const [],
    this.isVip = false,
    this.isBroadcaster = false,
    this.logins = const [],
    this.extra,
    this.account,
    this.apple,
    this.facebook,
    this.flag,
    this.gid,
    this.google,
    this.inviteCode,
    this.isTest,
    this.loginIp,
    this.oAuthId,
    this.pDirector,
    this.pStaff,
    this.pSupervisor,
    this.regIp,
    this.cdnUrl,
    this.sex,
    this.fans,
    this.isLike,
    this.status,
    this.tags,
    this.email,
    this.password,
    this.createAt,
    this.loginTime,
  });

  /// 取得主要頭像的 ImageProvider
  ImageProvider<Object> get avatarImage {
    final raw = avatarUrl;
    final cdn = cdnUrl;

    if (raw.isEmpty) return const AssetImage('assets/my_icon_defult.jpeg');
    if (raw.isDataUri) {
      try { return MemoryImage(base64Decode(raw)); } catch (_) {
        return const AssetImage('assets/my_icon_defult.jpeg');
      }
    }
    if (raw.isHttp)   return CachedNetworkImageProvider(raw);
    if (raw.isLocalAbs) return FileImage(File(raw));
    if (raw.isServerRelative) return CachedNetworkImageProvider(joinCdnIfNeeded(raw, cdn));
    // 其他情況（例如奇怪的相對檔名）直接當本地檔嘗試
    return FileImage(File(raw));
  }

  /// 個人生活照（不包含第一張頭像）
  List<String> get gallery =>
      photoURL.where((e) => e.isNotEmpty).skip(1).toList();

  /// 主要登入方式
  LoginMethod? get primaryLogin {
    if (logins.isEmpty) return null;
    return logins.firstWhere((e) => e.isPrimary, orElse: () => logins.first);
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: (json['uid'] ?? json['id'] ?? '').toString(),
      displayName: json['nick_name']?.toString() ?? 'Guest',
      photoURL: (json['avatar'] as List? ?? []).map((e) => e.toString()).toList(),
      isVip: (json['vip'] ?? 0) == 1,
      isBroadcaster: (json['flag'] ?? 1) == 2,
      logins: (json['logins'] as List? ?? [])
          .map((e) => LoginMethod.fromJson(e))
          .toList(),
      extra: json['detail'] ?? {},

      account: json['account']?.toString(),
      apple: json['apple']?.toString(),
      facebook: json['facebook']?.toString(),
      flag: json['flag'],
      gid: json['gid'],
      google: json['google']?.toString(),
      inviteCode: json['invite_code']?.toString(),
      isTest: json['is_test'],
      loginIp: json['login_ip']?.toString(),
      oAuthId: json['o_auth_id']?.toString(),
      pDirector: json['p_director']?.toString(),
      pStaff: json['p_staff']?.toString(),
      pSupervisor: json['p_supervisor']?.toString(),
      regIp: json['reg_ip']?.toString(),
      cdnUrl: json['cdn_url'] ?? '',
      sex: json['sex'],
      fans: json['fans'],
      isLike: json['is_like'],
      status: json['status'],
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
      email: json['email']?.toString(),
      password: json['pwd']?.toString(),
      createAt: json['create_at'],
      loginTime: json['update_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'nick_name': displayName,
      'avatar': photoURL,
      'vip': isVip ? 1 : 0,
      'flag': isBroadcaster ? 2 : 1,
      'logins': logins.map((e) => e.toJson()).toList(),
      'detail': extra,
      'account': account,
      'apple': apple,
      'facebook': facebook,
      'gid': gid,
      'google': google,
      'invite_code': inviteCode,
      'is_test': isTest,
      'login_ip': loginIp,
      'o_auth_id': oAuthId,
      'p_director': pDirector,
      'p_staff': pStaff,
      'p_supervisor': pSupervisor,
      'cdn_url': cdnUrl,
      'reg_ip': regIp,
      'sex': sex,
      'fans': fans,
      'is_like': isLike,
      'status': status,
      'tags': tags,
      'email': email,
      'pwd': password,
      'create_at': createAt,
      'update_at': loginTime,
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
    String? account,
    String? apple,
    String? facebook,
    int? flag,
    int? gid,
    String? google,
    String? inviteCode,
    int? isTest,
    String? loginIp,
    String? oAuthId,
    String? pDirector,
    String? pStaff,
    String? pSupervisor,
    String? regIp,
    String? cdnUrl,
    int? sex,
    int? fans,
    int? isLike,
    int? status,
    List<String>? tags,
    String? email,
    String? password,
    int? createAt,
    int? loginTime,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isVip: isVip ?? this.isVip,
      isBroadcaster: isBroadcaster ?? this.isBroadcaster,
      logins: logins ?? this.logins,
      extra: extra ?? this.extra,
      account: account ?? this.account,
      apple: apple ?? this.apple,
      facebook: facebook ?? this.facebook,
      flag: flag ?? this.flag,
      gid: gid ?? this.gid,
      google: google ?? this.google,
      inviteCode: inviteCode ?? this.inviteCode,
      isTest: isTest ?? this.isTest,
      loginIp: loginIp ?? this.loginIp,
      oAuthId: oAuthId ?? this.oAuthId,
      pDirector: pDirector ?? this.pDirector,
      pStaff: pStaff ?? this.pStaff,
      pSupervisor: pSupervisor ?? this.pSupervisor,
      cdnUrl: cdnUrl ?? this.cdnUrl,
      regIp: regIp ?? this.regIp,
      sex: sex ?? this.sex,
      fans: fans ?? this.fans,
      isLike: isLike ?? this.isLike,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      email: email ?? this.email,
      password: password ?? this.password,
      createAt: createAt ?? this.createAt,
      loginTime: loginTime ?? this.loginTime,
    );
  }
}

extension _CdnJoinX on String? {
  String joinCdn(String? base) {
    final p = this ?? '';
    if (p.isEmpty) return p;

    // 這些情況都「不要拼」
    if (p.isHttp || p.isDataUri || p.isContentUri || p.isLocalAbs) return p;

    if (base == null || base.isEmpty) return p;
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final path = p.startsWith('/') ? p : '/$p';
    return '$b$path';
  }
}


