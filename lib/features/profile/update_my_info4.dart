import 'dart:io';

import 'package:dio/dio.dart';
import 'package:djs_live_stream/features/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/error_handler.dart';
import '../../core/user_local_storage.dart';
import '../../l10n/l10n.dart';
import '../home/home_screen.dart';
import '../mine/user_repository_provider.dart';

class UpdateMyInfoPage4 extends ConsumerStatefulWidget {
  const UpdateMyInfoPage4({super.key});

  @override
  ConsumerState<UpdateMyInfoPage4> createState() => _UpdateMyInfoPage4State();
}

class _UpdateMyInfoPage4State extends ConsumerState<UpdateMyInfoPage4> {
  File? _selectedImage;
  static const int _kMaxBytes1GiB = 1024 * 1024 * 1024; // 1 GiB


  bool _isProbablyImage(String path, [String? mimeType]) {
    if (mimeType != null && mimeType.toLowerCase().startsWith('image/')) {
      return true;
    }
    final p = path.toLowerCase();
    const exts = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic', '.heif'];
    return exts.any((e) => p.endsWith(e));
  }

  String _msgForApi(ApiException e) {
    final t = S.of(context);
    final m = (e.message).trim(); // 保持原有優先取 server message 的行為
    if (m.isNotEmpty) return m;
    switch (e.code) {
      case 401: return t.apiErrLoginExpired;
      case 413: return t.apiErrPayloadTooLarge;
      case 422: return t.apiErrUnprocessable;
      case 429: return t.apiErrTooManyRequests;
      default:  return t.apiErrServiceGeneric;
    }
  }

  bool _isNetworkIssue(Object e) {
    if (e is DioException) {
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
      if (s.contains('timed out') ||
          s.contains('failed host lookup') ||
          s.contains('network is unreachable') ||
          s.contains('sslhandshake') ||
          s.contains('connection closed')) return true;
    } else if (e is SocketException) {
      return true;
    }
    return false;
  }

  void _onFinish() async {
    final t = S.of(context);
    if (_selectedImage == null) {
      Fluttertoast.showToast(msg: t.pickPhotoFirst);
      return;
    }

    final file = _selectedImage!;
    if (!await file.exists()) {
      Fluttertoast.showToast(msg: t.pickPhotoFirst);
      return;
    }
    if (!_isProbablyImage(file.path)) {
      Fluttertoast.showToast(msg: t.uploadImagesOnly);
      return;
    }
    final size = await file.length();
    if (size > _kMaxBytes1GiB) {
      Fluttertoast.showToast(msg: t.uploadLimitMaxSize('1G'));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final repo = ref.read(userRepositoryProvider);
      final user = ref.read(userProfileProvider);
      if (user == null) throw Exception(t.userNotLoggedIn);

      // 1. 上傳圖片到 S3
      final s3Url = await repo.uploadToS3Avatar(file);

      // 2. 拼接 CDN URL + file_url
      final fullUrl = "${user.cdnUrl}$s3Url";

      // 3. 更新 photoURL（只保留這張）
      final updatedUser = user.copyWith(photoURL: [fullUrl]);

      // 4. 本地更新 user state
      ref.read(userProfileProvider.notifier).setUser(updatedUser);
      await UserLocalStorage.saveUser(updatedUser);

      // 5. API 上傳
      final updateData = {
        'avatar': [fullUrl],
        'nick_name': user.displayName ?? 'user',
        'sex': user.sex,
        'detail': {
          'age': (user.extra?['age'] ?? '').toString().replaceAll('岁', ''),
        },
      };
      await repo.updateMemberInfo(updateData);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } on ApiException catch (e) {
      Fluttertoast.showToast(msg: _msgForApi(e));
      Navigator.of(context).pop();
    } on DioException catch (e) {
      final msg = _isNetworkIssue(e) ? S.of(context).netIssueRetryLater : (e.message ?? S.of(context).uploadFailed);
      Fluttertoast.showToast(msg: msg);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint("上傳失敗: $e");
      final msg = e.toString().contains('未登入') ? S.of(context).userNotLoggedIn : S.of(context).uploadFailed;
      Fluttertoast.showToast(msg: msg);
      Navigator.of(context).pop();
    }
  }

  Widget _buildProgressIndicator() {
    const totalSteps = 4;
    const currentStep = 4;
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 5,
            decoration: BoxDecoration(
              color: isActive ? Colors.red : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(t.setupLastStep, style: const TextStyle(fontSize: 14, color: Colors.black)),
                  const SizedBox(height: 8),
                  Text(t.setupYourPhoto, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(t.setupPhotoSubtitle, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 30),

                  // 上傳區
                  GestureDetector(
                    onTap: _pickImage,
                    child: Center(
                      child: Container(
                        height: 288,
                        width: 288,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _selectedImage == null
                            ? const Icon(Icons.add, size: 48, color: Colors.grey)
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 示範圖片
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PhotoExample(label: t.photoSampleClear),
                      _PhotoExample(label: t.photoSampleSmile),
                      _PhotoExample(label: t.photoSampleClearFeatures),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // 固定底部按鈕
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: _onFinish,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFA770), Color(0xFFD247FE)]),
                  borderRadius: BorderRadius.circular(22),
                ),
                height: 48,
                child: Center(
                  child: Text(
                    t.setupFinish,
                    style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final t = S.of(context);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    if (!await file.exists()) {
      Fluttertoast.showToast(msg: t.pickFailedRetry);
      return;
    }

    final okType = _isProbablyImage(pickedFile.path, pickedFile.mimeType);
    if (!okType) {
      Fluttertoast.showToast(msg: t.uploadImagesOnly);
      return;
    }

    final size = await file.length();
    if (size > _kMaxBytes1GiB) {
      Fluttertoast.showToast(msg: t.uploadLimitMaxSize('1G'));
      return;
    }

    setState(() => _selectedImage = file);
  }
}

class _PhotoExample extends StatelessWidget {
  final String label;
  const _PhotoExample({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            "assets/pic_my_info4.png",
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}