import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../features/mine/user_repository_provider.dart';
import '../features/profile/profile_controller.dart';
import 'app_lifecycle.dart';
import 'nav_helpers.dart';


/// push_token_registrar.dart
class PushTokenRegistrar {
  PushTokenRegistrar._();
  static final PushTokenRegistrar I = PushTokenRegistrar._();

  static const _kFcm  = 'push.fcm';
  static const _kVoip = 'push.voip';

  String? _fcm;
  String? _voip;
  bool _wiredFcm = false;

  /// App 啟動就呼叫（不會打後端，只負責蒐集 token & 綁事件）
  Future<void> initCollectors(WidgetRef ref) async {
    // 先載入快取
    final sp = await SharedPreferences.getInstance();
    _fcm  = sp.getString(_kFcm);
    _voip = sp.getString(_kVoip);

    // 綁定 FCM（Android 一定有；iOS 有 FCM 的話也會有值）
    if (!_wiredFcm) {
      _wiredFcm = true;
      final fm = FirebaseMessaging.instance;
      try {
        await fm.setAutoInitEnabled(true);
        if (Platform.isIOS) { await fm.requestPermission(); }
        // 取一次
        final cur = await fm.getToken().timeout(const Duration(seconds: 4));
        if (cur != null && cur != _fcm) {
          _fcm = cur;
          await sp.setString(_kFcm, cur);
          _maybeUpload(ref, reason: 'fcm-initial');
        }
        // 監聽變更
        fm.onTokenRefresh.listen((t) async {
          _fcm = t;
          await sp.setString(_kFcm, t);
          _maybeUpload(ref, reason: 'fcm-refresh');
        });
      } catch (e) {
        debugPrint('[PUSH] FCM unavailable: $e'); // 華為等裝置會走到這裡，沒關係
      }
    }

    // 綁原生的 PushKit → Dart 的 voip.token（見下一節）
    await _bindVoipChannel(ref);
  }

  /// 登入/切帳號後呼叫一次（或在監聽 userProfileProvider 時呼叫）
  Future<void> onLogin(WidgetRef ref) async {
    await _maybeUpload(ref, reason: 'login');
  }

  /// 登出時（若要）可直接刪除後端資料；目前先不變更
  Future<void> onLogout(WidgetRef ref) async {
    // 可選：呼叫 deleteDeviceToken
  }

  // ---- internal ----
  Future<void> _bindVoipChannel(WidgetRef ref) async {
    const ch = MethodChannel('app.callkit'); // <- 統一
    ch.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'voipToken': {
          final token = (call.arguments as Map)['token'] as String?;
          if (token != null && token.isNotEmpty && token != _voip) {
            _voip = token;
            final sp = await SharedPreferences.getInstance();
            await sp.setString(_kVoip, token);
            _maybeUpload(ref, reason: 'voip-update');
          }
          break;
        }
        case 'incoming': {
          final m = Map<String, dynamic>.from(call.arguments as Map);
          final payload = Map<String, dynamic>.from(m['payload'] ?? {});
          debugPrint('[[VOIP][incoming]] $payload');
          break;
        }
        case 'answer': {
          final m = Map<String, dynamic>.from(call.arguments as Map);
          final payload = Map<String, dynamic>.from(m['payload'] ?? {});
          debugPrint('[[VOIP][answer]] $payload');
          goToLiveFromPayload(payload); // 直接進房
          break;
        }
        case 'end': {
          final m = Map<String, dynamic>.from(call.arguments as Map);
          final payload = Map<String, dynamic>.from(m['payload'] ?? {});
          debugPrint('[[VOIP][end]] $payload'); // ★
          break;
        }
        default:
        // ignore
          break;
      }
    });

    // 通知原生：Dart 已就緒（若原生已拿到 token，會立刻回推）
    try { await ch.invokeMethod('voip.requestToken'); } catch (_) {}
  }

  Future<void> _maybeUpload(WidgetRef ref, {required String reason}) async {
    final user = ref.read(userProfileProvider);
    if (user == null) return; // 未登入不打

    final repo     = ref.read(userRepositoryProvider);
    final install  = await InstallId.get();
    final platform = Platform.isIOS ? 'ios' : 'android';
    final pkg      = await PackageInfo.fromPlatform();

    // 沒任一 token 也可以上報（讓後端清空），但通常 iOS 一定有 voip / Android 一定有 fcm
    final bodySig = jsonEncode({
      'uid'   : user.uid,
      'dev'   : install,
      'plat'  : platform,
      'pkg'   : pkg.packageName,
      'ver'   : pkg.version,
      'fcm'   : _fcm ?? '',
      'voip'  : _voip ?? '',
    });

    debugPrint('[PUSH] upsert ($reason) fcm=${_fcm?.substring(0,8)}… voip=${_voip?.substring(0,8)}…');

    await repo.upsertDeviceToken(
      userId: user.uid,
      deviceId: install,
      platform: platform,
      appId: pkg.packageName,
      appVersion: pkg.version,
      fcmToken: _fcm,
      voipToken: _voip,
    );

  }
}

class InstallId {
  static const _k = 'install_id';
  static String? _cached;

  static Future<String> get() async {
    if (_cached != null) return _cached!;
    final sp = await SharedPreferences.getInstance();
    var v = sp.getString(_k);
    if (v == null || v.isEmpty) {
      v = const Uuid().v4();
      await sp.setString(_k, v);
    }
    _cached = v;
    return v!;
  }
}