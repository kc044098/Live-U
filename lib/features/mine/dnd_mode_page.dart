import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'model/dnd_state.dart';

class DndModePage extends ConsumerStatefulWidget {
  const DndModePage({super.key});

  @override
  ConsumerState<DndModePage> createState() => _DndModePageState();
}

class _DndModePageState extends ConsumerState<DndModePage> {
  @override
  void initState() {
    super.initState();
    // 進頁先讀後端設定作為預設
    // 這裡直接讀 notifier 安全；若你有 context 依賴可包在 postFrame
    ref.read(dndProvider.notifier).fetchRemote();
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

  @override
  Widget build(BuildContext context) {
    final dnd = ref.watch(dndProvider);
    final ctrl = ref.read(dndProvider.notifier);
    const bg = Color(0xFFF6F6F6);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black54),
        title: const Text('免扰模式',
            style: TextStyle(fontSize: 16, color: Colors.black)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // 說明 + 開關
          Container(
            decoration: _card(),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 90, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('视频勿扰',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        dnd.isActive
                            ? '已开启。在此期间，后台会将你的状态设为忙碌，别人无法发起视频聊天'
                            : '选择一个时长开启免扰。开启后期间别人无法和你进行视频聊天',
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black54, height: 1.3),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 8,
                  child: CupertinoSwitch(
                    value: dnd.isActive,
                    onChanged: (v) async {
                      await ctrl.toggle(v);
                      if (!mounted) return;
                      final id = ref.read(dndProvider).selectedId;
                      final msg =
                      id == 0 ? '已关闭免扰' : '已开启免扰（${kDndOptions[id] ?? ''}）';
                      Fluttertoast.showToast(msg: msg);
                      setState(() {});
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
              children: kDndOptions.entries.map((e) {
                final id = e.key;
                final label = e.value;
                final selected = dnd.selectedId == id;

                return InkWell(
                  onTap: () async {
                    await ctrl.setById(id);
                    if (!mounted) return;
                    Fluttertoast.showToast(msg: '已开启免扰（$label）');
                    setState(() {});
                  },
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      border:
                      Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                    ),
                    child: Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 15,
                            color: selected
                                ? const Color(0xFFFF4D67)
                                : Colors.black87,
                            fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          const Icon(Icons.check,
                              color: Color(0xFFFF4D67), size: 20),
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
}