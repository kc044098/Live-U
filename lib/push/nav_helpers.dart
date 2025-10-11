import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ws/event_dedupe.dart';
import '../data/models/user_model.dart';
import '../features/message/message_chat_page.dart';
import '../features/profile/profile_controller.dart';
import '../globals.dart';
import '../routes/app_routes.dart';

// 取得 ProviderContainer（主 isolate 前景/被喚醒時可用；背景 FCM 不會用到）
ProviderContainer? get provider_container {
  final ctx = rootNavigatorKey.currentContext;
  if (ctx == null) return null;
  try { return ProviderScope.containerOf(ctx, listen: false); } catch (_) { return null; }
}

UserModel? get _me => provider_container?.read(userProfileProvider);
String? get avatarUrl =>  _me?.avatarUrl;
String? get cdnUrl => _me?.cdnUrl;

// 取第一張頭像相對路徑/URL
String firstAvatar(dynamic v) {
  if (v is List && v.isNotEmpty) return '${v.first}';
  if (v is String) return v;
  return '';
}

// CDN 拼 URL
String joinCdn(String base, String p) {
  if (p.isEmpty || p.startsWith('http')) return p;
  final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  final q = p.startsWith('/') ? p.substring(1) : p;
  return '$b/$q';
}

Map<String, dynamic> normalize(RemoteMessage m) {
  final d = Map<String, dynamic>.from(m.data);
  final inner = d['data'];
  if (inner is String) {
    try {
      final j = jsonDecode(inner);
      if (j is Map) d.addAll(Map<String, dynamic>.from(j));
    } catch (_) {}
  } else if (inner is Map) {
    d.addAll(Map<String, dynamic>.from(inner));
  }
  return d;
}

// 進直播間（使用你給的 arguments）
void goToLiveFromPayload(Map<String, dynamic> data) {
  debugPrint('[[NAV][LIVE]] room=${data['channel_id'] ?? data['roomId']} uid=${_me?.uid} token?=${(data['token'] ?? '').toString().isNotEmpty}'); // ★

  final me = _me; if (me == null) return;
  final cdn = me.cdnUrl ?? '';

  final roomId  = (data['channel_id'] ?? data['roomId'] ?? '').toString();
  final token   = (data['token'] ?? data['agora_token'] ?? '').toString();
  final fromUid = int.tryParse('${data['uid'] ?? data['from_uid'] ?? ''}') ?? -1;
  final needCam = (int.tryParse('${data['flag'] ?? 1}') ?? 1) == 1;
  final name    = (data['nick_name'] ?? 'Call').toString();
  final avatar  = joinCdn(cdn, firstAvatar(data['avatar']));

  Navigator.of(rootNavigatorKey.currentContext!, rootNavigator: true)
      .pushReplacementNamed(
    AppRoutes.broadcaster,
    arguments: {
      'roomId'       : roomId,
      'token'        : token,
      'uid'          : me.uid,
      'title'        : name,
      'hostName'     : me.displayName,
      'isCallMode'   : true,
      'asBroadcaster': true,
      'remoteUid'    : fromUid,
      'callFlag'     : needCam ? 1 : 2,
      'peerAvatar'   : avatar,
    },
  );
}

// 進聊天室（用你的頁面建構子）
void openChatFromPayload(Map<String, dynamic> data) {
  final me = _me; if (me == null) return;
  final cdn = me.cdnUrl ?? '';
  final myId = int.tryParse(me.uid) ?? -1;

  final from = int.tryParse('${data['uid'] ?? ''}') ?? -1;
  final to   = int.tryParse('${data['to_uid'] ?? ''}') ?? -1;
  final partnerUid = (to == myId) ? from : to;

  final name      = (data['nick_name'] ?? 'User $partnerUid').toString();
  final avatarUrl = joinCdn(cdn, firstAvatar(data['avatar']));

  Navigator.of(rootNavigatorKey.currentContext!, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => MessageChatPage(
        partnerName  : name,
        partnerAvatar: avatarUrl.isNotEmpty ? avatarUrl : 'assets/my_icon_defult.jpeg',
        vipLevel     : 0,
        statusText   : 1,
        partnerUid   : partnerUid,
      ),
    ),
  );
}