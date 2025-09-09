import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final callTimerProvider = ChangeNotifierProvider<CallTimer>((ref) {
  final t = CallTimer();
  ref.onDispose(() => t.dispose());
  return t;
});

class CallTimer extends ChangeNotifier {
  Timer? _ticker;
  DateTime? _startAt;

  bool get running => _ticker != null && _startAt != null;
  DateTime? get startAt => _startAt;

  int get elapsedSec {
    if (_startAt == null) return 0;
    final s = DateTime.now().difference(_startAt!).inSeconds;
    return s < 0 ? 0 : s;
  }

  String get text {
    final s = elapsedSec;
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return (h > 0) ? '${two(h)}:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
  }

  void start({DateTime? startFrom}) {
    // 若已在跑，不要重複啟動
    if (_ticker != null) return;
    _startAt ??= startFrom ?? DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    notifyListeners();
  }

  void stopButKeep() { // 停止 ticking 但保留開始時間（很少用）
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void reset() { // 掛斷時重置
    _ticker?.cancel();
    _ticker = null;
    _startAt = null;
    notifyListeners();
  }
}
