// models/app_update.dart
class AppUpdateInfo {
  final String version;   // 例如 v1.0.0 或 1.0.0
  final String title;
  final String content;   // 多行說明
  final int flag;         // 你後端自用
  final bool isMust;      // 1=強更
  final bool isShow;      // 1/2 顯示（依你後端定義）

  AppUpdateInfo({
    required this.version,
    required this.title,
    required this.content,
    required this.flag,
    required this.isMust,
    required this.isShow,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> j) {
    final d = (j['data'] ?? j) as Map<String, dynamic>;
    int asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return AppUpdateInfo(
      version : (d['version'] ?? '').toString(),
      title   : (d['title'] ?? '').toString(),
      content : (d['content'] ?? '').toString(),
      flag    : asInt(d['flag']),
      isMust  : asInt(d['is_must']) == 1,
      // 你給的例子是 2；若你後端規範「1=不顯示、2=顯示」，這裡就判斷 ==2
      isShow  : asInt(d['is_show']) == 2 || asInt(d['is_show']) == 1,
    );
  }
}

/// 版本字串比較（支援前綴 v / V）
/// return >0 表示 a > b；0 相等；<0 表示 a < b
int compareVersions(String a, String b) {
  int toInt(String s) => int.tryParse(s) ?? 0;
  String norm(String s) => s.trim().toLowerCase().replaceFirst(RegExp(r'^v'), '');
  final A = norm(a).split('.');
  final B = norm(b).split('.');
  final len = (A.length > B.length ? A.length : B.length);
  for (var i = 0; i < len; i++) {
    final ai = i < A.length ? toInt(A[i]) : 0;
    final bi = i < B.length ? toInt(B[i]) : 0;
    if (ai != bi) return ai - bi;
  }
  return 0;
}
