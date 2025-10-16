// services/update_service.dart
import 'dart:io' show Platform;
import 'package:djs_live_stream/update/version_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../config/providers/app_config_provider.dart';
import 'app_update.dart';

class UpdateService {
  final Ref ref;
  UpdateService(this.ref);

  static const _kSkipKey = 'skip_update_version';

  Future<void> checkAndPromptIOS(BuildContext context) async {
    if (!Platform.isIOS) return;

    final repo = ref.read(versionRepositoryProvider);
    final info = await repo.fetchLatestForIOS();
    if (info == null) return;
    if (!info.isShow) return;

    final pkg = await PackageInfo.fromPlatform();
    final local = pkg.version; // iOS 的 CFBundleShortVersionString
    final need = compareVersions(info.version, local) > 0;
    if (!need) return;

    // 避免使用者按了「稍後」同一版本一直彈
    final sp = await SharedPreferences.getInstance();
    final skipped = sp.getString(_kSkipKey);
    if (skipped == info.version && !info.isMust) return;

    await _showUpdateDialog(context, info);

    // 強更：不允許跳過
    if (!info.isMust) {
      // 使用者若選「稍後」，在 Dialog 裡會寫入 skip。
    }
  }

  Future<void> _showUpdateDialog(BuildContext context, AppUpdateInfo info) async {
    final cfg = ref.read(appConfigProvider);
    final appStoreId = cfg.appStoreId; // 我們前面建議在 release 寫死 Apple ID

    String storeUrl() {
        return 'itms-apps://apps.apple.com/app/id$appStoreId';
    }

    Future<void> goStore() async {
      final url = storeUrl();
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }

    final content = info.content.replaceAll(r'\n', '\n'); // 後端若傳了轉義換行

    await showCupertinoDialog(
      context: context,
      barrierDismissible: !info.isMust,
      builder: (_) {
        return CupertinoAlertDialog(
          title: Text(info.title.isEmpty ? '發現新版本' : info.title),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(content.isEmpty ? '建議更新到最新版本以獲得最佳體驗' : content),
          ),
          actions: [
            if (!info.isMust)
              CupertinoDialogAction(
                onPressed: () async {
                  final sp = await SharedPreferences.getInstance();
                  await sp.setString(UpdateService._kSkipKey, info.version);
                  Navigator.of(context).pop();
                },
                child: const Text('稍後'),
              ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                await goStore();
                // 強更時可選擇不關閉對話框，直到使用者回來；這裡關掉即可
                Navigator.of(context).pop();
              },
              child: const Text('立即更新'),
            ),
          ],
        );
      },
    );
  }
}