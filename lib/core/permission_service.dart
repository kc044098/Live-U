import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermission {
  microphone,
  camera,
  photosRead,
  photosAdd,          // 存到相簿
  locationWhenInUse,
  locationAlways,
  notification,
}

class PermissionService {
  static Permission _map(AppPermission p) {
    switch (p) {
      case AppPermission.microphone:       return Permission.microphone;
      case AppPermission.camera:           return Permission.camera;
      case AppPermission.photosRead:       return Permission.photos;           // iOS 14+ 會回傳 limited/denied/granted
      case AppPermission.photosAdd:        return Permission.photosAddOnly;    // 只寫入
      case AppPermission.locationWhenInUse:return Permission.locationWhenInUse;
      case AppPermission.locationAlways:   return Permission.locationAlways;
      case AppPermission.notification:     return Permission.notification;
    }
  }

  static Future<PermissionStatus> status(AppPermission p) async {
    if (!Platform.isAndroid && !Platform.isIOS) return PermissionStatus.granted;
    return _map(p).status;
  }

  static Future<bool> ensure(
      AppPermission p, {
        BuildContext? context,
        String? rationale,          // 可放 pre-permission 說明
        bool openSettingsIfLocked = true,
      }) async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    final perm = _map(p);
    var st = await perm.status;

    if (st.isGranted) return true;

    // optional：先顯示自家說明，再觸發 request（UX 會好很多）
    if (rationale != null && context != null && (st.isDenied || st.isLimited)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('需要權限'),
          content: Text(rationale),
          actions: [
            TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('稍後')),
            TextButton(onPressed: () => Navigator.pop(_, true),  child: const Text('允許')),
          ],
        ),
      );
      if (ok != true) return false;
    }

    // 觸發系統彈窗
    st = await perm.request();
    if (st.isGranted) return true;

    // 永久拒絕/受限 → 引導去設定
    if ((st.isPermanentlyDenied || st.isRestricted) && openSettingsIfLocked) {
      if (context != null) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('開啟權限'),
            content: const Text('請至「設定」開啟所需權限以使用此功能'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('取消')),
              TextButton(onPressed: () { openAppSettings(); Navigator.pop(_, true); }, child: const Text('前往設定')),
            ],
          ),
        );
      } else {
        openAppSettings();
      }
    }
    return false;
  }

  /// 批次（依序）請求，一個失敗就停
  static Future<bool> ensureBatch(List<AppPermission> list, {BuildContext? context}) async {
    for (final p in list) {
      final ok = await ensure(p, context: context);
      if (!ok) return false;
    }
    return true;
  }

  /// 針對情境的封裝
  static Future<bool> forCall({required bool video, BuildContext? context}) async {
    final list = <AppPermission>[
      AppPermission.microphone,
      if (video) AppPermission.camera,
      AppPermission.notification, // 來電提醒
    ];
    return ensureBatch(list, context: context);
  }

  static Future<bool> forPicker({BuildContext? context}) async {
    // 若你用 image_picker 走相簿，先要讀取；用 PHPicker 可省略
    return ensure(AppPermission.photosRead, context: context);
  }

  static Future<bool> forSaveToAlbum({BuildContext? context}) async {
    return ensure(AppPermission.photosAdd, context: context);
  }

  static Future<bool> forLocation({required bool background, BuildContext? context}) async {
    return ensure(background ? AppPermission.locationAlways : AppPermission.locationWhenInUse, context: context);
  }
}
