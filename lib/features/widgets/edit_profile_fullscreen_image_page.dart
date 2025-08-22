// edit_profile_fullscreen_image_page.dart
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/member_video_model.dart';
import '../../data/network/avatar_cache.dart';
import '../live/member_video_feed_state.dart';
import '../live/video_repository_provider.dart';
import '../profile/profile_controller.dart';

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FullscreenImagePage extends ConsumerStatefulWidget {
  final MemberVideoModel item;
  const FullscreenImagePage({super.key, required this.item});

  @override
  ConsumerState<FullscreenImagePage> createState() => _FullscreenImagePageState();
}

class _FullscreenImagePageState extends ConsumerState<FullscreenImagePage> {
  late String _selectedCategory;
  final TextEditingController _textController = TextEditingController();

  // 原始資料（用於比對）
  late final String _origTitle;
  late final int _origIsTop;

  String _isTopToCategory(int isTop) => isTop == 1 ? '精選' : '日常';
  int _categoryToIsTop(String cat) => cat == '精選' ? 1 : 2;

  bool get _hasChanges {
    final t = _textController.text.trim();
    final isTop = _categoryToIsTop(_selectedCategory);
    // 僅比較 title 與 is_top
    return (t != _origTitle) || (isTop != _origIsTop);
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = _isTopToCategory(widget.item.isTop);
    _textController.text = widget.item.title;

    // 初始化原始資料，做差異比對用
    _origTitle = widget.item.title;
    _origIsTop = widget.item.isTop;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // 樂觀送出：只在有變更時送，且不等待回應（不跳詢問 / 不顯示 dialog）
  void _saveChangesOptimistically() {
    if (!_hasChanges) {
      Navigator.pop(context, {'updated': false});
      return;
    }

    final id = widget.item.id;
    final title = _textController.text.trim();
    final isTop = _categoryToIsTop(_selectedCategory);

    // 先把結果回傳給呼叫端（列表可立即套用變更）
    Navigator.pop(context, {
      'updated': true,
      'id': id,
      'title': title,
      'isTop': isTop,
    });

    // 再在背景發 API，不阻塞 UI
    final repo = ref.read(videoRepositoryProvider);
    // 你的视频更新 API 僅需三個欄位：id, title, is_top
    // 這裡不 await，樂觀更新
    // ignore: discarded_futures
    repo.updateVideo(id: id, title: title, isTop: isTop).catchError((e, _) {
      // 失敗可視專案需求上報或記錄；此頁已經關閉，不彈框
      debugPrint('videoUpdate failed: $e');
    });
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 48));
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      errorWidget: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 48)),
    );
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
        extendBodyBehindAppBar: true,
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
        ),
        body: Stack(
          children: [
            Center(child: _buildImage(widget.item.coverUrl)),
            Positioned(
              left: 16,
              right: 16,
              bottom: 50,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 24, backgroundImage: user?.avatarImage),
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
