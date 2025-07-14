import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';


class LiveVideoItem extends StatefulWidget {
  final String name;
  final String image;
  final String videoPath;

  const LiveVideoItem({
    super.key,
    required this.name,
    required this.image,
    required this.videoPath,
  });

  @override
  State<LiveVideoItem> createState() => _LiveVideoItemState();
}

class _LiveVideoItemState extends State<LiveVideoItem> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.videoPath.startsWith('http')) {
      _controller = VideoPlayerController.network(widget.videoPath);
    } else if (widget.videoPath.startsWith('/')) {
      _controller = VideoPlayerController.file(File(widget.videoPath));
    } else {
      _controller = VideoPlayerController.asset(widget.videoPath);
    }

    _controller.initialize().then((_) {
      setState(() {});
      _controller.setLooping(true);
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _controller.value.isInitialized
            ? SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
        )
            : const Center(child: CircularProgressIndicator()),

        // 主播名稱
        Positioned(
          bottom: 80,
          left: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(backgroundImage: AssetImage(widget.image)),
              const SizedBox(height: 8),
              Text(widget.name,
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }
}
