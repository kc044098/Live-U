// edit_profile_fullscreen_image_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/profile_controller.dart';

class FullscreenImagePage extends ConsumerStatefulWidget {
  final String imagePath;

  const FullscreenImagePage({super.key, required this.imagePath});

  @override
  ConsumerState<FullscreenImagePage> createState() =>
      _FullscreenImagePageState();
}

class _FullscreenImagePageState extends ConsumerState<FullscreenImagePage> {
  String _selectedCategory = '精選';
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // **全螢幕圖片**
          Center(
            child: Image.asset(
              widget.imagePath,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // **返回鍵**
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // **左下角個人資訊 + 輸入框 + 分類按鈕**
          Positioned(
            left: 16,
            right: 16,
            bottom: 50,
            child: Column(
              children: [
                // 個人資訊
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: (() {
                            final extra = user?.extra ?? {};
                            final photo1 = extra['photo1'] as String?;
                            if (photo1 != null && photo1.isNotEmpty) {
                              return MemoryImage(base64Decode(photo1)) as ImageProvider;
                            }
                            return const AssetImage('assets/my_icon_defult.jpeg');
                          })(),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user?.displayName ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (user?.isVip ?? false)
                              Container(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                                  ),
                                ),
                                child: const Text(
                                  'VIP',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 輸入框 + 分類按鈕
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // **輸入框（動態寬度）**
                    Builder(
                      builder: (context) {
                        final textLength = _textController.text.length;

                        if (textLength <= 14) {
                          return IntrinsicWidth(
                            child: Container(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 8, top: 4, bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextField(
                                controller: _textController,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                keyboardType: TextInputType.text,
                                minLines: 1,
                                maxLines: 1,
                                decoration: const InputDecoration(
                                  hintText: '請輸入內容...',
                                  hintStyle: TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          );
                        } else {
                          return Flexible(
                            child: Container(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 8, top: 4, bottom: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextField(
                                controller: _textController,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                keyboardType: TextInputType.multiline,
                                minLines: 1,
                                maxLines: null,
                                decoration: const InputDecoration(
                                  hintText: '請輸入內容...',
                                  hintStyle: TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),

                    // **分類按鈕**
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        backgroundColor: _selectedCategory == '精選'
                            ? const Color(0xFFFF4D67)
                            : const Color(0xFF3A9EFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding:
                        const EdgeInsets.only(left: 25, right: 15),
                      ),
                      onPressed: () => _showCategoryBottomSheet(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedCategory,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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