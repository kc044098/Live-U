import 'package:shared_preferences/shared_preferences.dart';

class CrossIsolateSeen {
  static const _spKey = 'dedupe_recent_v1';
  static const _cap = 512;
  static const _ttl = Duration(minutes: 10);

  static Map<String,int>? _cache; // 每個 isolate 自己的快取

  static Future<Map<String,int>> _load() async {
    if (_cache != null) return _cache!;
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_spKey) ?? const [];
    final now = DateTime.now().millisecondsSinceEpoch;

    final m = <String,int>{};
    for (final line in list) {
      final i = line.lastIndexOf('|');
      if (i <= 0) continue;
      final uuid = line.substring(0, i);
      final ts = int.tryParse(line.substring(i + 1)) ?? 0;
      if (now - ts <= _ttl.inMilliseconds) m[uuid] = ts;
    }
    _cache = m;
    return m;
  }

  static Future<void> _save(Map<String,int> m) async {
    // 修剪 TTL + 容量
    final now = DateTime.now().millisecondsSinceEpoch;
    m.removeWhere((_, ts) => now - ts > _ttl.inMilliseconds);
    while (m.length > _cap) {
      // 刪最舊
      String? oldestKey; int oldestTs = 1<<62;
      m.forEach((k,ts){ if (ts < oldestTs) { oldestTs=ts; oldestKey=k; }});
      if (oldestKey != null) m.remove(oldestKey);
    }
    final sp = await SharedPreferences.getInstance();
    final list = m.entries.map((e) => '${e.key}|${e.value}').toList(growable:false);
    await sp.setStringList(_spKey, list);
    _cache = m;
  }

  /// 記錄一個 uuid 已處理
  static Future<void> remember(String uuid) async {
    final m = await _load();
    m[uuid] = DateTime.now().millisecondsSinceEpoch;
    await _save(m);
  }

  /// 回傳是否在 TTL 內處理過（不會新增）
  static Future<bool> wasSeen(String uuid) async {
    final m = await _load();
    final ts = m[uuid];
    if (ts == null) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final ok = now - ts <= _ttl.inMilliseconds;
    if (!ok) { m.remove(uuid); await _save(m); }
    return ok;
  }

  /// 取最近所有 uuid（用來灌回 EventDeduper）
  static Future<Iterable<String>> recentUuids() async {
    final m = await _load();
    return m.keys;
  }
}
