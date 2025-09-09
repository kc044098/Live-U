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

extension TakeIf on String {
  String? takeIf(bool Function(String) pred) => pred(this) ? this : null;
}