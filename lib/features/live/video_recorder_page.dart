import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'video_preview_page.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:path_provider/path_provider.dart';

import 'package:image_picker/image_picker.dart';

class VideoRecorderPage extends StatefulWidget {
  const VideoRecorderPage({super.key});

  @override
  State<VideoRecorderPage> createState() => _VideoRecorderPageState();
}

class _VideoRecorderPageState extends State<VideoRecorderPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool isVideoMode = true;
  bool _isRecording = false;
  bool _musicAdded = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isNotEmpty) {
      _controller = CameraController(_cameras![0], ResolutionPreset.high);
      await _controller!.initialize();
      if (mounted) setState(() {});
    }
  }

  Future<void> _startRecording() async {
    if (_controller != null && !_isRecording) {
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopRecording() async {
    if (_controller != null && _isRecording) {
      final file = await _controller!.stopVideoRecording();
      setState(() => _isRecording = false);

      final thumbPath = await _generateThumbnail(file.path);

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPreviewPage(
            videoPath: file.path,
            thumbnailPath: thumbPath,
            musicAdded: _musicAdded,
          ),
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final picture = await _controller!.takePicture();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPreviewPage(
            videoPath: picture.path,
            thumbnailPath: picture.path,
            musicAdded: false,
          ),
        ),
      );
    } catch (e) {
      debugPrint('拍照失敗: $e');
    }
  }

  /// === 新增相冊選擇邏輯 ===
  Future<void> _pickFromGallery() async {
    XFile? pickedFile;
    if (isVideoMode) {
      // 只允許影片
      pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      // 只允許圖片
      pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    }

    if (pickedFile == null) return;

    String? thumbPath;
    if (isVideoMode) {
      thumbPath = await _generateThumbnail(pickedFile.path);
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPreviewPage(
          videoPath: pickedFile!.path,
          thumbnailPath: isVideoMode ? thumbPath : pickedFile.path,
          musicAdded: isVideoMode ? _musicAdded : false,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 相機畫面
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          /// 左上角返回
          Positioned(
            top: MediaQuery.of(context).padding.top + 40,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          /// 添加音樂（只在視頻模式顯示）
          if (isVideoMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 44,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.music_note, color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() => _musicAdded = true);
                            Fluttertoast.showToast(msg: "已添加音樂");
                          },
                          child: const Text('添加音樂', style: TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() => _musicAdded = false);
                            Fluttertoast.showToast(msg: "已清除音樂");
                          },
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          /// 右側功能
          Positioned(
            top: MediaQuery.of(context).size.height * 0.14,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSideButton('assets/icon_reverse.svg', '翻轉', _onReverseCamera),
                const SizedBox(height: 20),
                _buildSideButton('assets/icon_beauty.svg', '美顏', _onBeauty),
                const SizedBox(height: 20),
                _buildSideButton('assets/icon_filter.svg', '濾鏡', _onFilter),
              ],
            ),
          ),

          /// 模式切換
          _buildBottomModeSwitch(),

          /// 底部功能按鈕
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// 特效
                  GestureDetector(
                    onTap: () => Fluttertoast.showToast(msg: "特效功能尚未實現"),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset('assets/icon_special.svg', width: 36, height: 36),
                        const SizedBox(height: 4),
                        const Text('特效', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 50),

                  /// 拍照 / 錄影按鈕
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (isVideoMode) {
                        _isRecording ? _stopRecording() : _startRecording();
                      } else {
                        _takePhoto();
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: SvgPicture.asset(
                        isVideoMode
                            ? (_isRecording
                            ? 'assets/pic_stop_button.svg'
                            : 'assets/pic_start_button.svg')
                            : 'assets/pic_start_button.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 50),

                  /// 相冊（根據模式選擇圖片或影片）
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset('assets/icon_upload.svg', width: 36, height: 36),
                        const SizedBox(height: 4),
                        const Text('相冊', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideButton(String assetPath, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SvgPicture.asset(assetPath, width: 32, height: 32),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  void _onReverseCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      Fluttertoast.showToast(msg: "沒有其他鏡頭可切換");
      return;
    }
    final lensDirection = _controller?.description.lensDirection;
    final newDescription = (lensDirection == CameraLensDirection.front)
        ? _cameras!.firstWhere((d) => d.lensDirection == CameraLensDirection.back)
        : _cameras!.firstWhere((d) => d.lensDirection == CameraLensDirection.front);
    await _controller?.dispose();
    _controller = CameraController(newDescription, ResolutionPreset.high);
    await _controller!.initialize();
    setState(() {});
  }

  void _onBeauty() => Fluttertoast.showToast(msg: "美顏功能尚未實現");
  void _onFilter() => Fluttertoast.showToast(msg: "濾鏡功能尚未實現");

  Widget _buildBottomModeSwitch() {
    final screenWidth = MediaQuery.of(context).size.width;
    const buttonSpacing = 110.0;

    return Positioned(
      bottom: 160,
      left: 0,
      right: 0,
      child: SizedBox(
        width: screenWidth,
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: isVideoMode ? (screenWidth / 2 - 60) : (screenWidth / 2 + buttonSpacing - 60),
              child: _buildModeButton(
                text: '視頻',
                icon: Icons.videocam,
                isActive: isVideoMode,
                onTap: () => setState(() => isVideoMode = true),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: isVideoMode ? (screenWidth / 2 + buttonSpacing - 60) : (screenWidth / 2 - 60),
              child: _buildModeButton(
                text: '圖片',
                icon: Icons.image,
                isActive: !isVideoMode,
                onTap: () => setState(() => isVideoMode = false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required String text,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.black54 : Colors.black26,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.white70, size: 20),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<String?> _generateThumbnail(String videoPath) async {
    final tempDir = await getTemporaryDirectory();
    final thumbPath = await vt.VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: tempDir.path,
      imageFormat: vt.ImageFormat.PNG,
      maxHeight: 200,
      quality: 75,
    );
    return thumbPath;
  }
}
