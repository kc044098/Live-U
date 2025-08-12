// edit_profile_fullscreen_video_player_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/member_video_model.dart';
import '../live/video_repository_provider.dart';
import '../profile/profile_controller.dart';

import 'dart:io';

class FullscreenVideoPlayerPage extends ConsumerStatefulWidget {
  final MemberVideoModel item; // ✅ 改成吃整個 item，才能回傳 id/title/isTop

  const FullscreenVideoPlayerPage({super.key, required this.item});

  @override
  ConsumerState<FullscreenVideoPlayerPage> createState() => _FullscreenVideoPlayerPageState();
}

class _FullscreenVideoPlayerPageState extends ConsumerState<FullscreenVideoPlayerPage> {
  late VideoPlayerController _controller;

  // 與圖片頁一致：標題 + 分類（精選/日常） + 樂觀上傳
  late String _selectedCategory;
  final TextEditingController _textController = TextEditingController();
  late final String _origTitle;
  late final int _origIsTop;

  String _isTopToCategory(int isTop) => isTop == 1 ? '精選' : '日常';
  int _categoryToIsTop(String cat) => cat == '精選' ? 1 : 2;

  bool get _hasChanges {
    final t = _textController.text.trim();
    final isTop = _categoryToIsTop(_selectedCategory);
    return (t != _origTitle) || (isTop != _origIsTop);
  }

  @override
  void initState() {
    super.initState();
    // 初始化 UI 狀態
    _selectedCategory = _isTopToCategory(widget.item.isTop);
    _textController.text = widget.item.title;
    _origTitle = widget.item.title;
    _origIsTop = widget.item.isTop;

    _initController();
  }

  Future<void> _initController() async {
    final p = widget.item.videoUrl;
    if (p.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(p));
    } else if (p.startsWith('file://') || File(p).existsSync()) {
      _controller = VideoPlayerController.file(File(p.startsWith('file://') ? Uri.parse(p).toFilePath() : p));
    } else {
      _controller = VideoPlayerController.asset(p);
    }

    await _controller.initialize();
    await _controller.setLooping(true); // ✅ 循環播放
    await _controller.play();           // ✅ 自動播放
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  // 與圖片頁相同的樂觀上傳
  void _saveChangesOptimistically() {
    if (!_hasChanges) {
      Navigator.pop(context, {'updated': false});
      return;
    }

    final id = widget.item.id;
    final title = _textController.text.trim();
    final isTop = _categoryToIsTop(_selectedCategory);

    // 先回傳給上一頁，立即更新列表
    Navigator.pop(context, {
      'updated': true,
      'id': id,
      'title': title,
      'isTop': isTop,
    });

    // 背景送 API（不阻塞、不跳框）
    final repo = ref.read(videoRepositoryProvider);
    // ignore: discarded_futures
    repo.updateVideo(id: id, title: title, isTop: isTop).catchError((e, _) {
      debugPrint('videoUpdate failed: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          _saveChangesOptimistically();
          return false;
        }
        Navigator.pop(context, {'updated': false});
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_hasChanges) {
                _saveChangesOptimistically();
              } else {
                Navigator.pop(context, {'updated': false});
              }
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _hasChanges ? _saveChangesOptimistically : null,
                icon: const Icon(Icons.check, color: Colors.white, size: 18),
                label: const Text('完成', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // 全螢幕影片（覆蓋，不提供點擊暫停）
            if (_controller.value.isInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),

            // 左下角資訊 + 編輯區（與圖片頁一致）
            Positioned(
              left: 16,
              right: 16,
              bottom: 50,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 24, backgroundImage: user?.avatarImage), // ✅ 換成你的 avatarImage（含快取版本）
                      const SizedBox(width: 8),
                      if (user != null)
                        Row(
                          children: [
                            Text(user.displayName ?? '', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            if (user.isVip)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: const LinearGradient(colors: [Color(0xFFFFA770), Color(0xFFD247FE)]),
                                ),
                                child: const Text('VIP', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500)),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
                          child: TextField(
                            controller: _textController,
                            onChanged: (_) => setState(() {}), // 讓完成按鈕依變更啟用/停用
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: '請輸入內容...',
                              hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedCategory == '精選'
                              ? const Color(0xFFFF4D67)
                              : const Color(0xFF3A9EFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                        onPressed: () => _showCategoryBottomSheet(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_selectedCategory, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
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
      ),
    );
  }

  void _showCategoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('選擇分類', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                title: Text('精選', style: TextStyle(color: _selectedCategory == '精選' ? const Color(0xFFFF4D67) : Colors.black)),
                onTap: () {
                  setState(() => _selectedCategory = '精選');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('日常', style: TextStyle(color: _selectedCategory == '日常' ? const Color(0xFF3A9EFF) : Colors.black)),
                onTap: () {
                  setState(() => _selectedCategory = '日常');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}