import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig(
    apiBaseUrl: Env.apiBase,     // ← 不再硬寫
    wsUrl: Env.wsUrl,            // ← 自動用 wss 並帶上固定 path
    faceUnityLicense: const String.fromEnvironment('FACE_UNITY', defaultValue: ''),
    appStoreId: "6753199146",  // apple id
  );
});

class AppConfig {
  final String apiBaseUrl;
  static String agoraAppId = "143b1c410344405d91219406af395459";
  final String wsUrl;
  static String token = "";
  final String faceUnityLicense;
  final String? appStoreId;

  const AppConfig({
    required this.apiBaseUrl,
    required this.wsUrl,
    required this.faceUnityLicense,
    this.appStoreId,
  });
}
