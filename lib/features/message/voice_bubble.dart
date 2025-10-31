import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'chat_message.dart';

class VoiceBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback onPlay;

  const VoiceBubble({Key? key, required this.message, required this.onPlay})
      : super(key: key);

  @override
  _VoiceBubbleState createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  bool _showExpandIcon = true;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant VoiceBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkPlayState();
  }

  void _checkPlayState() {
    if (widget.message.isPlaying) {
      _startBlinking();
    } else {
      _stopBlinking();
    }
  }

  void _startBlinking() {
    if (_timer != null && _timer!.isActive) return; // 防止重複啟動
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        _showExpandIcon = !_showExpandIcon;
        setState(() {});
      }
    });
  }

  void _stopBlinking() {
    _timer?.cancel();
    setState(() => _showExpandIcon = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPlay,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${widget.message.isPlaying ? widget.message.currentPosition : (widget.message.duration ?? 0)}"',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (_showExpandIcon)
              SvgPicture.asset('assets/voice_vector_expend.svg'),
            SvgPicture.asset('assets/voice_vector.svg'),
          ],
        ),
      ),
    );
  }
}
