import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';

class VideoDetailsPage extends StatefulWidget {
  final String videoPath;
  final String? thumbnailPath;

  const VideoDetailsPage({
    super.key,
    required this.videoPath,
    this.thumbnailPath,
  });

  @override
  State<VideoDetailsPage> createState() => _VideoDetailsPageState();
}

class _VideoDetailsPageState extends State<VideoDetailsPage> {
  final _descController = TextEditingController();
  String _selectedCategory = "選擇分類";
  final ImagePicker _picker = ImagePicker();
  String? _coverPath;

  Future<void> _pickCoverImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (file == null) return;

    setState(() {
      _coverPath = file.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayPath = _coverPath ?? widget.thumbnailPath;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context, 'resume'),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                // TODO: 發布邏輯
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB56B), Color(0xFFDF65F8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '發布',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 描述輸入框
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '記錄這一刻',
                  hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 封面縮略圖 (可點擊)
            GestureDetector(
              onTap: _pickCoverImage,
              child: Stack(
                children: [
                  displayPath != null
                      ? Image.file(File(displayPath),
                      width: 100, height: 100, fit: BoxFit.cover)
                      : const Icon(Icons.image, size: 100, color: Colors.grey),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: const Text(
                        '編輯封面',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 分類選擇
            GestureDetector(
              onTap: () {
                _showCategoryBottomSheet(context);
              },
              child: Row(
                children: [
                  SvgPicture.asset('assets/icon_paper.svg'),
                  const SizedBox(width: 8),
                  Text(_selectedCategory, style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 標題 & 關閉
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const Center(
                        child: Text(
                          '選擇分類',
                          style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          iconSize: 20,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 精選
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = '精選';
                      });
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '精選',
                        style: TextStyle(
                          color: _selectedCategory == '精選'
                              ? const Color(0xFFFF4D67)
                              : Colors.black,
                          fontSize: 16,
                          fontWeight: _selectedCategory == '精選'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  const Divider(
                    color: Color(0xFFF5F5F5),
                    indent: 16,
                    endIndent: 16,
                  ),

                  // 日常
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = '日常';
                      });
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        '日常',
                        style: TextStyle(
                          color: _selectedCategory == '日常'
                              ? const Color(0xFF3A9EFF)
                              : Colors.black,
                          fontSize: 16,
                          fontWeight: _selectedCategory == '日常'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}