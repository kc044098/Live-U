import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';


class DndModePage extends ConsumerStatefulWidget {
  const DndModePage({super.key});

  @override
  ConsumerState<DndModePage> createState() => _DndModePageState();
}

class _DndModePageState extends ConsumerState<DndModePage> {
  // 與設計稿一致的選項
  final _options = const <String, Duration>{
    '15分钟': Duration(minutes: 15),
    '30分钟': Duration(minutes: 30),
    '1小时' : Duration(hours: 1),
    '6小时' : Duration(hours: 6),
    '12小时': Duration(hours: 12),
    '24小时': Duration(hours: 24),
  };

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final dnd  = ref.watch(dndProvider);
    final ctrl = ref.read(dndProvider.notifier);

    const bg = Color(0xFFF6F6F6);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg, // ✅ 與頁面同色
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black54),
        title: const Text('免扰模式',
            style: TextStyle(fontSize: 16, color: Colors.black)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // 視頻勿擾 + 右上角 Switch
          Container(
            decoration: _card(),
            child: Stack(
              children: [
                // 文字內容
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 90, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('视频勿扰',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        dnd.isActive
                            ? '已开启，至 ${_fmt(dnd.until!)} 结束。在此期间，任何人均不能和你进行视频聊天'
                            : '根据您设置的时间，在这个时间内任何人均不能和你进行视频聊天',
                        style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.3),
                      ),
                    ],
                  ),
                ),
                // 右上角開關（靠右靠上）
                Positioned(
                  right: 10,
                  top: 8,
                  child: CupertinoSwitch(
                    value: dnd.isActive,
                    onChanged: (v) async {
                      if (!v) {
                        await ctrl.disable(); // ✅ 行為等同原本 appbar「關閉」
                      } else {
                        final mins = dnd.selectedMinutes ?? 15;
                        await ctrl.enableFor(Duration(minutes: mins));
                        final until = ref.read(dndProvider).until!;
                        if (mounted) {
                          Fluttertoast.showToast(msg: '已开启免扰至 ${_fmt(until)}');
                        }
                      }
                      if (mounted) setState(() {});
                    },
                    activeColor: Colors.pinkAccent,
                    trackColor: const Color(0xFFEDEDED),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 時長選擇
          Container(
            decoration: _card(),
            child: Column(
              children: _options.entries.map((e) {
                final label    = e.key;
                final dur      = e.value;
                final selected = dnd.isActive && dnd.selectedMinutes == dur.inMinutes;

                return InkWell(
                  onTap: () async {
                    await ref.read(dndProvider.notifier).enableFor(dur);
                    if (!mounted) return;
                    final until = ref.read(dndProvider).until!;
                    Fluttertoast.showToast(msg: '已开启免扰至 ${_fmt(until)}');

                    setState(() {}); // 立即刷新勾選
                  },
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                    ),
                    child: Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            color: selected ? const Color(0xFFFF4D67) : Colors.black87,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          const Icon(Icons.check, color: Color(0xFFFF4D67), size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(10),
    boxShadow: const [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );
}

/* ------------------------- 狀態管理（沿用你原本） ------------------------- */

final dndProvider = StateNotifierProvider<DndController, DndState>((ref) {
  return DndController()..load();
});

class DndState {
  final DateTime? until;       // null 表示未開啟
  final int? selectedMinutes;  // 記錄選中的時長（分鐘）
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
      selectedMinutes: active ? mins : mins, // 即使未開啟也保留上次選擇
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
    state = DndState(until: null, selectedMinutes: state.selectedMinutes);
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kPrefUntil);
    _timer?.cancel();
  }

  void _armTimer() {
    _timer?.cancel();
    if (!state.isActive) return;
    final ms = state.remaining.inMilliseconds;
    _timer = Timer(Duration(milliseconds: ms.clamp(0, 24 * 3600 * 1000)), () async {
      state = DndState(until: null, selectedMinutes: state.selectedMinutes);
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_kPrefUntil);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
