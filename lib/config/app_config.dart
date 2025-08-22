class AppConfig {
  final String apiBaseUrl;
  static String agoraAppId = "143b1c410344405d91219406af395459";
  final String wsUrl;
  static String token = "";
  final String faceUnityLicense;

  const AppConfig({
    required this.apiBaseUrl,
    required this.wsUrl,
    required this.faceUnityLicense,
  });
}

// 在 main.dart 中依 dart-define 判斷載入
// flutter build apk --dart-define=ENV=staging
// flutter build apk --dart-define=ENV=production
