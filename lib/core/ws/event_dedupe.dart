import 'dart:collection';

class EventDeduper {
  EventDeduper._();
  static final EventDeduper I = EventDeduper._();

  final _seen = LinkedHashMap<String, int>();
  static const _ttlMs = 10 * 60 * 1000; // 10 分鐘
  static const _cap   = 4096;

  bool isDupAndRemember(Map<String, dynamic> m) {
    final uuid = extractUuid(m);
    if (uuid == null || uuid.isEmpty) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_seen.length % 128 == 0) {
      final cutoff = now - _ttlMs;
      _seen.removeWhere((_, ts) => ts < cutoff);
    }
    final ts = _seen[uuid];
    if (ts != null && now - ts <= _ttlMs) return true;

    _seen[uuid] = now;
    if (_seen.length > _cap) _seen.remove(_seen.keys.first);
    return false;
  }

  String? extractUuid(Map<String, dynamic> m) {
    String? pick(Map mm, List<String> ks) {
      for (final k in ks) {
        final v = mm[k];
        if (v == null) continue;
        final s = v.toString();
        if (s.isNotEmpty) return s;
      }
      return null;
    }
    final top = pick(m, ['uuid','UUID']);
    if (top != null) return top;

    Map<String, dynamic> asMap(dynamic v) =>
        (v is Map) ? v.map((k, v) => MapEntry(k.toString(), v)) : <String, dynamic>{};

    final d1 = asMap(m['data']);
    final d2 = asMap(m['Data']);
    final dd = d1.isNotEmpty ? d1 : d2;
    return pick(dd, ['uuid','UUID','id','Id']);
  }

  /// 將一批 uuid 灌入記憶體去重集合（用現在時刻當 ts）
  void seed(Iterable<String> uuids) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final u in uuids) {
      _seen[u] = now; // 直接使用你原本的 _seen
      if (_seen.length > EventDeduper._cap) {
        _seen.remove(_seen.keys.first);
      }
    }
  }
}