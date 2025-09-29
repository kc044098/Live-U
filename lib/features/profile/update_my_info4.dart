import 'dart:io';

import 'package:dio/dio.dart';
import 'package:djs_live_stream/features/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/error_handler.dart';
import '../../core/user_local_storage.dart';
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
    final m = (e.message ?? '').trim();
    if (m.isNotEmpty) return m;
    switch (e.code) {
      case 401: return '登入已失效，請重新登入';
      case 413: return '請求資料過大';
      case 422: return '參數不完整或不合法';
      case 429: return '操作太頻繁，稍後再試';
      default:  return '服務異常，請稍後再試';
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
    if (_selectedImage == null) {
      Fluttertoast.showToast(msg: "請先選擇照片");
      return;
    }

    // ✅ 送出前再做一次防呆校驗（型別/大小/存在）
    final file = _selectedImage!;
    if (!await file.exists()) {
      Fluttertoast.showToast(msg: "請先選擇照片");
      return;
    }
    if (!_isProbablyImage(file.path)) {
      Fluttertoast.showToast(msg: "只能上傳圖片檔案");
      return;
    }
    final size = await file.length();
    if (size > _kMaxBytes1GiB) {
      Fluttertoast.showToast(msg: "只能上傳1G以下的檔案");
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
      if (user == null) throw Exception("使用者未登入");

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

      Fluttertoast.showToast(msg: "個人資料已完成！");
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } on ApiException catch (e) {
      // 後端業務碼錯誤（如 4xx/業務邏輯失敗）
      Fluttertoast.showToast(msg: _msgForApi(e));
      Navigator.of(context).pop(); // 關掉 loading
    } on DioException catch (e) {
      // 連線/逾時/502-504 等
      final msg = _isNetworkIssue(e) ? '網路連線異常，請稍後重試' : (e.message ?? '上傳失敗');
      Fluttertoast.showToast(msg: msg);
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint("上傳失敗: $e");
      Fluttertoast.showToast(msg: e.toString().contains('未登入') ? '使用者未登入' : '上傳失敗');
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 可捲動內容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressIndicator(),
                  const SizedBox(height: 20),
                  const Text("最後一步",
                      style: TextStyle(fontSize: 14, color: Colors.black)),
                  const SizedBox(height: 8),
                  const Text(
                    "你的照片",
                    style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "上傳一張本人五官清晰的正面照",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
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
                            ? const Icon(Icons.add,
                            size: 48, color: Colors.grey)
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 示範圖片
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _PhotoExample(label: "無遮擋"),
                      _PhotoExample(label: "記得微笑"),
                      _PhotoExample(label: "五官清晰"),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // 固定底部按鈕
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: _onFinish,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                height: 48,
                child: const Center(
                  child: Text(
                    '完成',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, // 只允許相簿
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    final file = File(pickedFile.path);
    if (!await file.exists()) {
      Fluttertoast.showToast(msg: '選取失敗，請重試');
      return;
    }

    // 型別檢查：不是圖片就阻擋
    final okType = _isProbablyImage(pickedFile.path, pickedFile.mimeType);
    if (!okType) {
      Fluttertoast.showToast(msg: '只能上傳圖片檔案');
      return;
    }

    // 大小檢查：> 1G 阻擋
    final size = await file.length();
    if (size > _kMaxBytes1GiB) {
      Fluttertoast.showToast(msg: '只能上傳1G以下的檔案');
      return;
    }

    setState(() {
      _selectedImage = file;
    });
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