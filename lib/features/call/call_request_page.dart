import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:audioplayers/audioplayers.dart';

class CallRequestPage extends StatefulWidget {
  final String broadcasterId;
  final String broadcasterName;
  final String broadcasterImage;

  const CallRequestPage({
    super.key,
    required this.broadcasterId,
    required this.broadcasterName,
    required this.broadcasterImage,
  });

  @override
  State<CallRequestPage> createState() => _CallRequestPageState();
}

class _CallRequestPageState extends State<CallRequestPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playRingtone();
  }

  Future<void> _playRingtone() async {
    await Future.delayed(const Duration(seconds: 1));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop); // 循環播放
    await _audioPlayer.play(AssetSource('ringtone.wav'));
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/bg_calling.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: topPadding + 24, bottom: 32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 160),
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage(widget.broadcasterImage),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      widget.broadcasterName,
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                    const SizedBox(height: 24),
                    const Text('等待对方接听...',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 140),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset('assets/call_end.svg'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: topPadding + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              tooltip: '取消通話',
            ),
          ),
        ],
      ),
    );
  }
}
