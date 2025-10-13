extension PathX on String {
  bool get isHttp => startsWith('http://') || startsWith('https://');
  bool get isDataUri => startsWith('data:image');
  bool get isContentUri => startsWith('content://') || startsWith('file://');

  // 常見本地絕對路徑（Android/iOS）
  bool get isLocalAbs =>
      startsWith('/private/') ||   // iOS (真機 temp, docs 等)
          startsWith('/var/')     ||   // iOS（少數情況會是 /var）
          startsWith('/Users/')    ||  // iOS 模擬器
          startsWith('/storage/')  ||  // Android
          startsWith('/mnt/')      ||  // Android
          startsWith('/data/');         // Android app data

  /// 只有像 /avatar/xxx.jpg 這種「伺服器相對路徑」才回 true
  /// （本機絕對路徑一律 false）
  bool get isServerRelative => startsWith('/') && !isLocalAbs;

  /// 後端把 Google avatar 壓成 "/a/xxx" 這種短路徑
  bool get isGoogleShort   => startsWith('/a/');

}

String sanitizeAvatarUrl(String? raw, {String? cdnBase}) {
  final r = (raw ?? '').trim();
  if (r.isEmpty || r.isLocalAbs || r.isGoogleShort) return '';

  if (r.isHttp || r.isDataUri || r.isContentUri) return r;

  if (r.isServerRelative) {
    final base = (cdnBase ?? '').trim();
    if (base.isEmpty) return '';
    final b = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return '$b$r'; // r 以 "/" 開頭
  }

  // 其他不認得的相對字串，一律當空
  return '';
}

/// 只在「伺服器相對路徑」時拼 CDN，其餘直接回傳原字串
String joinCdnIfNeeded(String raw, String? cdnBase) {
  if (raw.isEmpty || raw.isHttp || raw.isDataUri || raw.isContentUri || raw.isLocalAbs) {
    return raw; // 本機檔 or 完整 URL 都不拼
  }
  if (!raw.isServerRelative) return raw; // 本地相對檔名也不拼
  if (cdnBase == null || cdnBase.isEmpty) return raw;

  final b = cdnBase.endsWith('/') ? cdnBase.substring(0, cdnBase.length - 1) : cdnBase;
  final p = raw.startsWith('/') ? raw : '/$raw';
  return '$b$p';
}