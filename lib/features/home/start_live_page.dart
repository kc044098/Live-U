// 開啟直播的設定頁面

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile/profile_controller.dart';
import '../../routes/app_routes.dart';

class StartLivePage extends ConsumerStatefulWidget {
  const StartLivePage({super.key});

  @override
  ConsumerState<StartLivePage> createState() => _StartLivePageState();
}

class _StartLivePageState extends ConsumerState<StartLivePage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('開啟直播'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.videoRecorder);
            },
            child: const Text(
              '发布动态',
              style: TextStyle(color: Colors.lightBlue),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('直播主：${profile.name}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: '直播間標題'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: '直播介紹'),
            ),
            const SizedBox(height: 80),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 實作開始直播邏輯
                  final roomId = 'room001';
                  Navigator.pushNamed(
                    context,
                    '/broadcaster',
                    arguments: {
                      'roomId': roomId,
                      'title': _titleController.text,
                      'desc': _descController.text,
                      'hostName': profile.name,
                    },
                  );
                },
                child: const Text('開始直播'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
