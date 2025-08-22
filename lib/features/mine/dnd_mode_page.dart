import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dnd_provider.dart';

class DndModePage extends ConsumerStatefulWidget {
  const DndModePage({super.key});

  @override
  ConsumerState<DndModePage> createState() => _DndModePageState();
}

class _DndModePageState extends ConsumerState<DndModePage> {
  // 选项（与截图一致）
  final _options = const <String, Duration>{
    '15分钟': Duration(minutes: 15),
    '30分钟': Duration(minutes: 30),
    '1小时':  Duration(hours: 1),
    '6小时':  Duration(hours: 6),
    '12小时': Duration(hours: 12),
    '24小时': Duration(hours: 24),
  };

  String _formatEndTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final dnd = ref.watch(dndProvider);
    final ctrl = ref.read(dndProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('免扰模式', style: TextStyle(fontSize: 16, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (dnd.isActive)
            TextButton(
              onPressed: () => ctrl.disable(),
              child: const Text('关闭', style: TextStyle(color: Color(0xFFFF4D67))),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFF6F6F6),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          // 顶部说明卡片
          Material(
            color: Colors.white,
            elevation: 1,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('视频勿扰',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    dnd.isActive
                        ? '已开启，至 ${_formatEndTime(dnd.until!)} 结束。在此期间，任何人均不能和你进行视频聊天'
                        : '根据您设置的时间，在这个时间内任何人均不能和你进行视频聊天',
                    style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 选项列表卡片
          Material(
            color: Colors.white,
            elevation: 1,
            borderRadius: BorderRadius.circular(10),
            child: Column(
              children: _options.entries.map((e) {
                final label = e.key;
                final dur   = e.value;
                final selected = dnd.isActive && dnd.selectedMinutes == dur.inMinutes;

                return InkWell(
                  onTap: () async {
                    await ref.read(dndProvider.notifier).enableFor(dur);
                    if (!mounted) return;
                    final until = ref.read(dndProvider).until!;
                    final h = until.hour.toString().padLeft(2, '0');
                    final m = until.minute.toString().padLeft(2, '0');
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text('已开启免扰至 $h:$m')));
                    setState(() {}); // 立刻刷新红字/勾选
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
}