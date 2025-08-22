import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_config.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig(
    apiBaseUrl: 'https://api.ludev.shop', // ← 這裡填你後端的 base URL
    wsUrl: 'wss://api.ludev.shop/api/im/index',
    faceUnityLicense: 'YOUR_FACE_UNITY_LICENSE_STRING', // ← 如未使用可填空字串
  );
});