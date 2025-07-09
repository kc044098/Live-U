import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoDetailsPage extends StatefulWidget {
  final String videoPath;

  const VideoDetailsPage({super.key, required this.videoPath});

  @override
  State<VideoDetailsPage> createState() => _VideoDetailsPageState();
}

class _VideoDetailsPageState extends State<VideoDetailsPage> {
  final _descController = TextEditingController();
  String? _selectedCategory;

  Future<void> _saveToDownloads() async {
    try {
      final videoFile = File(widget.videoPath);
      if (!videoFile.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('找不到影片檔案')),
        );
        return;
      }

      final appDir = await getApplicationDocumentsDirectory(); // App 私有目錄
      final downloadsDir = Directory('${appDir.path}/downloads');
      if (!downloadsDir.existsSync()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final newPath = '${downloadsDir.path}/$fileName';

      await videoFile.copy(newPath);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ 測試影片已儲存：$fileName')),
      );

      print('影片儲存路徑：$newPath');
    } catch (e) {
      print('儲存失敗：$e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ 儲存影片失敗')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey.shade100,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, 'resume'),
        ),
        actions: [
          TextButton(
            onPressed: _saveToDownloads,
            child: const Text('下載影片', style: TextStyle(color: Colors.lightBlueAccent)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 描述欄位
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: '記錄這一刻',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),
            // 封面（目前暫用加號圖示）
            SizedBox(
              width: 100,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black38),
                ),
                child: const Center(
                  child: Icon(Icons.add, size: 40, color: Colors.black26),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 分類 + 精選區塊
            Row(
              children: [
                const Icon(Icons.image, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('選擇分類', style: TextStyle(fontSize: 16)),
                const Spacer(),
                const Text('精選', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right),
              ],
            ),
          ],
        ),
      ),
    );
  }
}