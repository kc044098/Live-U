import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'video_preview_page.dart';

import 'package:fluttertoast/fluttertoast.dart';

class VideoRecorderPage extends StatefulWidget {
  const VideoRecorderPage({super.key});

  @override
  State<VideoRecorderPage> createState() => _VideoRecorderPageState();
}

class _VideoRecorderPageState extends State<VideoRecorderPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;
  bool _musicAdded = false;

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

      if (!mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPreviewPage(
            videoPath: file.path,
            musicAdded: _musicAdded, // ✅ 傳給預覽頁
          ),
        ),
      );

      // ✅ 判斷是否要清除 musicAdded
      if (result == false) {
        setState(() {
          _musicAdded = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onAddMusic() {
    setState(() {
      _musicAdded = true;
    });
    Fluttertoast.showToast(
      msg: "已添加音樂",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('錄製动态')),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          // ✅ 新增音樂按鈕
          Positioned(
            top: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: _onAddMusic,
              icon: const Icon(Icons.music_note),
              label: const Text('新增音樂'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: FloatingActionButton(
                onPressed: _isRecording ? _stopRecording : _startRecording,
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
                child: Icon(_isRecording ? Icons.stop : Icons.videocam),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
