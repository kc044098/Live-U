import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// dnd_provider.dart
final dndProvider = StateNotifierProvider<DndController, DndState>((ref) {
  return DndController()..load();
});

class DndState {
  final DateTime? until;       // null 表示未开启
  final int? selectedMinutes;  // 记录选了哪个选项（单位：分钟）
  const DndState({this.until, this.selectedMinutes});

  bool get isActive => until != null && until!.isAfter(DateTime.now());
  Duration get remaining => isActive ? until!.difference(DateTime.now()) : Duration.zero;
}

class DndController extends StateNotifier<DndState> {
  static const _kPrefUntil  = 'dnd_until_iso';
  static const _kPrefMinute = 'dnd_selected_minutes';
  Timer? _timer;

  DndController() : super(const DndState());

  Future<void> load() async {
    final sp   = await SharedPreferences.getInstance();
    final iso  = sp.getString(_kPrefUntil);
    final mins = sp.getInt(_kPrefMinute);
    final until = (iso != null && iso.isNotEmpty) ? DateTime.tryParse(iso) : null;

    final active = until != null && until.isAfter(DateTime.now());
    state = DndState(
      until: active ? until : null,
      selectedMinutes: active ? mins : null,
    );
    _armTimer();
  }

  Future<void> enableFor(Duration duration) async {
    final until = DateTime.now().add(duration);
    state = DndState(until: until, selectedMinutes: duration.inMinutes);

    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kPrefUntil, until.toIso8601String());
    await sp.setInt(_kPrefMinute, duration.inMinutes);
    _armTimer();
  }

  Future<void> disable() async {
    state = const DndState(until: null, selectedMinutes: null);
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kPrefUntil);
    await sp.remove(_kPrefMinute);
    _timer?.cancel();
  }

  void _armTimer() {
    _timer?.cancel();
    if (!state.isActive) return;
    final ms = state.remaining.inMilliseconds;
    _timer = Timer(Duration(milliseconds: ms.clamp(0, 24 * 3600 * 1000)), () async {
      state = const DndState(until: null, selectedMinutes: null);
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_kPrefUntil);
      await sp.remove(_kPrefMinute);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}