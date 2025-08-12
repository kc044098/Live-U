import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/network/api_client_provider.dart';
import '../../data/network/api_endpoints.dart';
import '../mine/user_repository_provider.dart';

class VideoDetailsPage extends ConsumerStatefulWidget {
  final String videoPath;
  final String? thumbnailPath;

  const VideoDetailsPage({
    super.key,
    required this.videoPath,
    this.thumbnailPath,
  });

  @override
  ConsumerState<VideoDetailsPage> createState() => _VideoDetailsPageState();
}

class _VideoDetailsPageState extends ConsumerState<VideoDetailsPage> {
  final _descController = TextEditingController();
  String _selectedCategory = "選擇分類";
  final ImagePicker _picker = ImagePicker();
  String? _coverPath;

  // 上傳狀態
  bool _isUploading = false;
  double _progress = 0;  // 0.0 - 1.0
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _descController.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }

  bool _isVideoPath(String path) {
    final lower = path.toLowerCase();
    const exts = ['.mp4', '.mov', '.m4v', '.avi', '.wmv', '.flv', '.webm'];
    return exts.any((ext) => lower.endsWith(ext));
  }

  Future<void> _pickCoverImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (file == null) return;
    setState(() => _coverPath = file.path);
  }

  Future<void> _onPublish() async {
    if (_isUploading) return;

    final api = ref.read(apiClientProvider);
    final repo = ref.read(userRepositoryProvider);
    final isVideo = _isVideoPath(widget.videoPath);
    final file = File(widget.videoPath);

    setState(() {
      _isUploading = true;
      _progress = 0;
      _cancelToken = CancelToken();
    });

    try {
      String? videoUrl;
      String? coverUrl;
      String? imageUrl;

      if (isVideo) {
        // 1) 先上傳影片（0% ~ 85%）
        videoUrl = await repo.uploadToS3(
          file: file,
          cancelToken: _cancelToken,
          onProgress: (sent, total) {
            setState(() {
              _progress = total == 0 ? 0 : (sent / total) * 0.85;
            });
          },
        );

        // 2) 上傳封面（可選，85% ~ 100%）
        final coverPath = _coverPath ?? widget.thumbnailPath;
        if (coverPath != null && coverPath.isNotEmpty && await File(coverPath).exists()) {
          coverUrl = await repo.uploadToS3(
            file: File(coverPath),
            cancelToken: _cancelToken,
            onProgress: (sent, total) {
              final part = total == 0 ? 0 : (sent / total) * 0.15;
              setState(() {
                _progress = 0.85 + part;
              });
            },
          );
        }
      } else {
        // 照片：單檔上傳（0% ~ 100%）
        imageUrl = await repo.uploadToS3(
          file: file,
          cancelToken: _cancelToken,
          onProgress: (sent, total) {
            setState(() {
              _progress = total == 0 ? 0 : (sent / total);
            });
          },
        );
      }

      // 3) 組 payload
      final payload = <String, dynamic>{
        'title': _descController.text.trim(),
        'is_top': _selectedCategory == '精選' ? 1 : 2,
        if (isVideo) 'video_url': videoUrl,
        if (isVideo && coverUrl != null) 'cover': coverUrl,
        if (!isVideo && imageUrl != null) 'img': [imageUrl], // 單張也用陣列
      };

      // 4) 通知後端建立動態
      final resp = await api.post(ApiEndpoints.momentCreate, data: payload);
      final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;
      if (raw is! Map || raw['code'] != 200) {
        throw Exception('建立動態失敗: $raw');
      }

      if (!mounted) return;
      Navigator.pop(context, 'resume');
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        Fluttertoast.showToast(msg: '已取消上傳');
      } else {
        Fluttertoast.showToast(msg: '上傳失敗: ${e.message}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: '上傳失敗: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _progress = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayPath = _coverPath ?? widget.thumbnailPath;

    return Stack(
      children: [
        Scaffold(
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
                  onTap: _isUploading ? null : _onPublish,
                  child: Opacity(
                    opacity: _isUploading ? 0.6 : 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB56B), Color(0xFFDF65F8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('發布', style: TextStyle(color: Colors.white, fontSize: 14)),
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
                // 描述
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

                // 封面（可點選更換）
                GestureDetector(
                  onTap: _isUploading ? null : _pickCoverImage,
                  child: Stack(
                    children: [
                      displayPath != null
                          ? Image.file(File(displayPath), width: 100, height: 100, fit: BoxFit.cover)
                          : const Icon(Icons.image, size: 100, color: Colors.grey),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: const Text('編輯封面', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 分類
                GestureDetector(
                  onTap: _isUploading ? null : () => _showCategoryBottomSheet(context),
                  child: Row(
                    children: [
                      SvgPicture.asset('assets/icon_paper.svg'),
                      const SizedBox(width: 8),
                      Text(_selectedCategory, style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Colors.black38),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ====== 上傳中覆蓋層 + 進度條 + 取消 ======
        if (_isUploading)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: Container(
                color: Colors.black.withOpacity(0.35),
                child: Center(
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('上傳中...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: _progress.clamp(0.0, 1.0)),
                        const SizedBox(height: 8),
                        Text('${(_progress * 100).toStringAsFixed(0)}%'),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            _cancelToken?.cancel('user cancel');
                          },
                          child: const Text('取消上傳'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
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
                      FocusScope.of(context).unfocus(); // 隱藏鍵盤
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
                      FocusScope.of(context).unfocus(); // 隱藏鍵盤
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