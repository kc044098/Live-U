import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';
import 'package:video_thumbnail/video_thumbnail.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ImagePicker _picker = ImagePicker();
  final List<XFile?> _mediaFiles = [null, null, null];
  final List<Uint8List?> _thumbnails = [null, null, null];

  Future<void> _pickMedia(int tappedIndex) async {
    final XFile? file = await _picker.pickMedia();
    if (file == null) return;

    final emptyIndex = _mediaFiles.indexWhere((x) => x == null);
    final indexToUpdate = _mediaFiles[tappedIndex] != null ? tappedIndex : emptyIndex;

    if (indexToUpdate == -1) return;

    Uint8List? thumbnailBytes;
    if (_isVideo(file)) {
      thumbnailBytes = await VideoThumbnail.thumbnailData(
        video: file.path,
        imageFormat: ImageFormat.PNG,
        maxWidth: 300,
        quality: 75,
      );
    }

    setState(() {
      _mediaFiles[indexToUpdate] = file;
      _thumbnails[indexToUpdate] = thumbnailBytes;
    });
  }

  bool _isVideo(XFile file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi');
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> profileItems = [
      {'label': '昵称', 'value': '琉璃碎梦心'},
      {'label': '性别', 'value': '女'},
      {'label': '生日', 'value': '20岁'},
      {'label': '身高', 'value': '0cm'},
      {'label': '体重', 'value': '0磅'},
      {'label': '三围', 'value': '胸围 0 腰围 0 臀围 0'},
      {'label': '城市', 'value': '武汉'},
      {'label': '工作', 'value': '人事'},
      {'label': '个人标签', 'value': '立即添加'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        centerTitle: true,
        leading: const BackButton(),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F8F8),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 📸 照片 / 影片 區域
          Row(
            children: List.generate(3, (index) {
              final file = _mediaFiles[index];
              final isVideo = file != null && _isVideo(file);
              final thumbnail = _thumbnails[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () => _pickMedia(index),
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                    height: 100,
                    child: Stack(
                      children: [
                        // 背景
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            image: (file != null && !isVideo)
                                ? DecorationImage(
                              image: FileImage(File(file.path)),
                              fit: BoxFit.cover,
                            )
                                : (file != null && isVideo && thumbnail != null)
                                ? DecorationImage(
                              image: MemoryImage(thumbnail),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: file == null
                              ? const Center(
                            child: Icon(Icons.add, size: 32, color: Colors.grey),
                          )
                              : null,
                        ),

                        // 如果是影片 → 播放 icon
                        if (file != null && isVideo)
                          const Center(
                            child: Icon(Icons.play_circle_fill,
                                size: 40, color: Colors.white),
                          ),

                        // 刪除按鈕 (右上角)
                        if (file != null)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _mediaFiles[index] = null;
                                  _thumbnails[index] = null;
                                });
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // ➕ Add more photos button
          OutlinedButton(
            onPressed: () {
              // TODO: Add more media behavior
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.pink),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Add more photos',
              style: TextStyle(fontSize: 16, color: Colors.pink),
            ),
          ),
          const SizedBox(height: 16),

          // 📋 資料列表
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: List.generate(profileItems.length, (index) {
                final item = profileItems[index];
                return Column(
                  children: [
                    ListTile(
                      title: Text(item['label']!, style: const TextStyle(fontSize: 14)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item['value']!,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                        ],
                      ),
                      onTap: () {
                        // TODO: 編輯項目
                      },
                    ),
                    if (index != profileItems.length - 1)
                      const Divider(height: 1, indent: 12, endIndent: 12),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
