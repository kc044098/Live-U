// chat_utils.dart
import 'dart:io';
import 'dart:math';

int nowSec() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

String joinCdn(String? base, String path) {
  if (path.isEmpty || path.startsWith('http')) return path;
  if (base == null || base.isEmpty) return path;
  final b = base.replaceFirst(RegExp(r'/+$'), '');
  final p = path.replaceFirst(RegExp(r'^/+'), '');
  return '$b/$p';
}

int deviceType() {
  if (Platform.isAndroid) return 2;
  if (Platform.isIOS) return 3;
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) return 4;
  return 4;
}

String genUuid(int myUid) {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final dev = deviceType();
  final rnd = Random().nextInt(9000000) + 1000000;
  return '$myUid-$ts-$dev-$rnd';
}

int? asIntDyn(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v');

int? msFromUuid(String id) {
  // 你的 uuid 形如：4-1757736634198-2-1143543
  // 取中間那段毫秒數
  if (id.isEmpty) return null;
  final parts = id.split('-');
  if (parts.length >= 2) return int.tryParse(parts[1]);
  final m = RegExp(r'^\d+-(\d+)-').firstMatch(id);
  return (m != null) ? int.tryParse(m.group(1)!) : null;
}

extension TakeIf on String {
  String? takeIf(bool Function(String) pred) => pred(this) ? this : null;
}