
class Env {
  static const _prod = 'https://api.liveu.live';
  static const _test = 'https://api.ludev.shop';

  // 可選：直接覆寫 HTTP/WS（比 ENV 優先）
  static const _apiBaseOverride = String.fromEnvironment('API_BASE', defaultValue: '');
  static const _wsOverride      = String.fromEnvironment('WS_URL',   defaultValue: '');

  // production / staging（預設：Release→production；Debug→staging）
  static const _env = String.fromEnvironment(
    'ENV',
    defaultValue: 'production',
    // defaultValue: kReleaseMode ? 'production' : 'staging',
  );

  static String get current => _env; // 方便 log

  static String get apiBase {
    if (_apiBaseOverride.isNotEmpty) return _apiBaseOverride;
    switch (_env) {
      case 'production':
      case 'prod':
        return _prod;
      case 'staging':
      default: return _test;
    }
  }

  /// 由 HTTP base 推導 WS；也可用 WS_URL 直接覆寫
  static String get wsUrl {
    if (_wsOverride.isNotEmpty) return _wsOverride;
    final u = Uri.parse(apiBase);
    return Uri(
      scheme: u.scheme == 'https' ? 'wss' : 'ws',
      host: u.host,
      port: u.hasPort ? u.port : null,
      path: '/api/im/index',
    ).toString();
  }

  static String get appleServiceId =>
      (_env == 'production') ? 'liveu.live.signin' : 'com.liveu.signin';

  static String get appleRedirectUri =>
      (_env == 'production')
          ? 'https://liveu-b966c.firebaseapp.com/__/auth/handler'
          : 'https://lu-test-abff5.firebaseapp.com/__/auth/handler';
}
