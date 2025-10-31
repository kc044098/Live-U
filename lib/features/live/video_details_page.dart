import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/error_handler.dart';
import '../../data/network/api_client_provider.dart';
import '../../data/network/api_endpoints.dart';
import '../../l10n/l10n.dart';
import '../../routes/app_routes.dart';
import '../mine/user_repository_provider.dart';
import '../profile/profile_controller.dart';

class VideoDetailsPage extends ConsumerStatefulWidget {
  final String videoPath;
  final String? thumbnailPath;
  final bool musicAdded;    // 是否選了音樂
  final String? musicPath;

  const VideoDetailsPage({
    super.key,
    required this.videoPath,
    this.thumbnailPath,
    this.musicAdded = false, // 給預設避免既有呼叫報錯
    this.musicPath,
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
  double _progress = 0; // 0.0 - 1.0
  CancelToken? _cancelToken;

  static const int _kMaxTitleLen = 300;

  // ===== 新增：追蹤當前階段（只用於錯誤訊息更精準） =====
  _Stage _stage = _Stage.none;

  String _selectedCategoryDisplay(S s) {
    if (_selectedCategory == '精選') return s.categoryFeatured;
    if (_selectedCategory == '日常') return s.categoryDaily;
    return s.selectCategory;
  }

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

    final s = S.of(context);

    final api = ref.read(apiClientProvider);
    final repo = ref.read(userRepositoryProvider);
    final isVideo = _isVideoPath(widget.videoPath);
    final file = File(widget.videoPath);

    setState(() {
      _isUploading = true;
      _progress = 0;
      _cancelToken = CancelToken();
      _stage = _Stage.none;
    });

    try {
      String? videoUrl;
      String? coverUrl;
      String? imageUrl;

      if (isVideo) {
        // 1) 先上傳影片（0% ~ 85%）
        _stage = _Stage.uploadVideo;
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
        if (coverPath != null &&
            coverPath.isNotEmpty &&
            await File(coverPath).exists()) {
          _stage = _Stage.uploadCover;
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
        _stage = _Stage.uploadImage;
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
      final String relativeAudio =
      (isVideo && widget.musicAdded && (widget.musicPath?.isNotEmpty ?? false))
          ? widget.musicPath!.trim()
          : '';

      final payload = <String, dynamic>{
        'title': _descController.text.trim(),
        'is_top': _selectedCategory == '精選' ? 1 : 2,
        if (isVideo) 'video_url': videoUrl,
        'audio_url': relativeAudio,
        if (isVideo && coverUrl != null) 'cover': coverUrl,
        if (!isVideo && imageUrl != null) 'img': [imageUrl], // 單張也用陣列
      };

      // 4) 通知後端建立動態（改用 postOk：非 200 直接拋 ApiException）
      _stage = _Stage.createMoment;
      await api.postOk(ApiEndpoints.momentCreate, data: payload);

      if (!mounted) return;
      Fluttertoast.showToast(msg: s.uploadSuccess);
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } on ApiException catch (e) {
      // 由 ApiClient._unwrapOrThrow 拋出：有業務 code 與友好訊息
      Fluttertoast.showToast(msg: _messageForApiException(e, _stage));
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        Fluttertoast.showToast(msg: S.of(context).uploadCanceled);
      } else {
        Fluttertoast.showToast(msg: _messageForDio(e, _stage));
      }
    } catch (e) {
      // 其他不可辨識錯誤
      debugPrint('上傳失敗(${_stage.name}): $e');
      Fluttertoast.showToast(msg: _fallbackMsgForStage(_stage));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _progress = 0;
          _stage = _Stage.none;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final displayPath = _coverPath ?? widget.thumbnailPath;
    final isBroadcaster = ref.watch(userProfileProvider)?.isBroadcaster == true;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.black87, size: 20),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB56B), Color(0xFFDF65F8)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text( s.publish,
                          style: TextStyle(color: Colors.white, fontSize: 14)),
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
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _descController,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(_kMaxTitleLen),
                    ],
                    maxLength: _kMaxTitleLen,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: s.momentHint,
                      hintStyle:
                      TextStyle(color: Color(0xFF999999), fontSize: 14),
                      counterText: '',
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
                          ? Image.file(File(displayPath),
                          width: 100, height: 100, fit: BoxFit.cover)
                          : const Icon(Icons.image,
                          size: 100, color: Colors.grey),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: Text(s.editCover,
                              style:
                              TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      )
                    ],
                  ),
                ),
                if (isBroadcaster) ...[
                  const SizedBox(height: 24),
                  // 分類
                  GestureDetector(
                    onTap: _isUploading
                        ? null
                        : () => _showCategoryBottomSheet(context),
                    child: Row(
                      children: [
                        SvgPicture.asset('assets/icon_paper.svg'),
                        const SizedBox(width: 8),
                        Text( _selectedCategoryDisplay(s),
                            style: const TextStyle(fontSize: 16)),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: Colors.black38),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ====== 上傳中覆蓋層 + 進度條 + 取消 ======
        if (_isUploading) _buildUploadingOverlay(),
      ],
    );
  }

  Widget _buildUploadingOverlay() {
    final s = S.of(context);
    final pct = ((_progress.clamp(0.0, 1.0)) * 100).toStringAsFixed(0);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true, // 背景不可點
        child: Container(
          color: Colors.black.withOpacity(0.35),
          child: Center(
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 100%
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF4D67),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 膠囊進度條
                  _GradientCapsuleProgress(value: _progress.clamp(0.0, 1.0)),
                  const SizedBox(height: 16),
                  Text(
                    s.uploadingVideo,
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryBottomSheet(BuildContext context) {
    final s = S.of(context);
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
                      Center(
                        child: Text(
                          s.selectCategory,
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
                        s.categoryFeatured,
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
                        s.categoryDaily,
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

  // ===== 新增：錯誤分類 & 對應訊息 =====

  String _messageForApiException(ApiException e, _Stage stage) {
    final code = e.code;
    final server = (e.message ?? '').trim();
    if (server.isNotEmpty) return server; // 優先用後端 message

    // 常見 code 的備用文案
    switch (code) {
      case 401:
        return '登入已失效，請重新登入';
      case 413:
        return _stageIsUpload(stage) ? '檔案過大，請壓縮後再試' : '請求資料過大';
      case 429:
        return '操作太頻繁，稍後再試';
      case 422:
        return '參數不完整或不合法';
      default:
        return _fallbackMsgForStage(stage);
    }
  }

  String _messageForDio(DioException e, _Stage stage) {
    // 網路形態
    if (_isNetworkIssue(e)) {
      return '網路連線異常，請稍後再試';
    }

    // HTTP 狀態碼
    final sc = e.response?.statusCode ?? 0;
    if (sc == 401) return '登入已失效，請重新登入';
    if (sc == 413) return _stageIsUpload(stage) ? '檔案過大，請壓縮後再試' : '請求資料過大';
    if (sc == 502 || sc == 503 || sc == 504) return '伺服器忙碌，請稍後再試';

    // 其他
    switch (stage) {
      case _Stage.uploadVideo:
        return '影片上傳失敗';
      case _Stage.uploadCover:
        return '封面上傳失敗';
      case _Stage.uploadImage:
        return '圖片上傳失敗';
      case _Stage.createMoment:
        return '建立動態失敗';
      case _Stage.none:
        return '發生錯誤';
    }
  }

  String _fallbackMsgForStage(_Stage stage) {
    switch (stage) {
      case _Stage.uploadVideo:
        return '影片上傳失敗';
      case _Stage.uploadCover:
        return '封面上傳失敗';
      case _Stage.uploadImage:
        return '圖片上傳失敗';
      case _Stage.createMoment:
        return '資料上傳失敗';
      case _Stage.none:
        return '資料上傳失敗';
    }
  }

  bool _stageIsUpload(_Stage s) =>
      s == _Stage.uploadVideo || s == _Stage.uploadCover || s == _Stage.uploadImage;

  bool _isNetworkIssue(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      default:
        break;
    }
    final sc = e.response?.statusCode ?? 0;
    if (sc == 502 || sc == 503 || sc == 504) return true;
    if (e.error is SocketException) return true;
    final s = e.message?.toLowerCase() ?? '';
    return s.contains('timed out') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('sslhandshake') ||
        s.contains('connection closed');
  }
}

// 只在本檔使用的小 enum（用於錯誤訊息更精準）
enum _Stage { none, uploadVideo, uploadCover, uploadImage, createMoment }

class _GradientCapsuleProgress extends StatelessWidget {
  final double value; // 0.0 ~ 1.0
  const _GradientCapsuleProgress({required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final fillW = (w * value).clamp(0.0, w);

        return Container(
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: fillW,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4D67), Color(0xFFFF8FB1)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
