import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../l10n/l10n.dart';

Future<bool> ensureMicCamForCall({
  required BuildContext context,
  required bool isVideo, // video -> mic+cam, voice -> mic only
}) async {
  final t = S.of(context);
  final req = <Permission>[Permission.microphone, if (isVideo) Permission.camera];

  // 先看目前狀態
  final statuses = await Future.wait(req.map((p) => p.status));
  final allGranted = statuses.every((s) => s == PermissionStatus.granted);
  if (allGranted) return true;

  // 發起請求
  final res = await req.request();
  final micOk = res[Permission.microphone] == PermissionStatus.granted;
  final camOk = !isVideo || res[Permission.camera] == PermissionStatus.granted;

  if (micOk && camOk) return true;

  // 永久拒絕 -> 引導去設定
  final perma = res.values.any((s) => s.isPermanentlyDenied);
  if (perma) {
    Fluttertoast.showToast(msg: t.micCamPermissionPermanentlyDenied);
    unawaited(openAppSettings());
  } else {
    Fluttertoast.showToast(msg: t.needMicCamPermission);
  }
  return false;
}
