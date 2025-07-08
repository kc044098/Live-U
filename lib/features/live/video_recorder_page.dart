import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'video_preview_page.dart';

class VideoRecorderPage extends StatefulWidget {
  const VideoRecorderPage({super.key});

  @override
  State<VideoRecorderPage> createState() => _VideoRecorderPageState();
}

class _VideoRecorderPageState extends State<VideoRecorderPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isRecording = false;

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

      // ✅ 導向預覽頁
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoPreviewPage(videoPath: file.path),
        ),
      );
    }
  }


  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
