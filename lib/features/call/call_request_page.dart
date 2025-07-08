import 'package:flutter/material.dart';

class CallRequestPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 📞 撥號內容 + 滾動適配各種裝置尺寸
          SingleChildScrollView(
            padding: EdgeInsets.only(top: topPadding + 24, bottom: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '正在撥打',
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    broadcasterName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CircleAvatar(
                    radius: 64,
                    backgroundImage: AssetImage(broadcasterImage),
                  ),
                  const SizedBox(height: 80),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Image.asset(
                      'assets/call_end.png', // 按鈕圖片放 assets 裡
                      width: 80,
                      height: 80,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔙 關閉按鈕（左上）
          Positioned(
            top: topPadding + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(context),
              tooltip: '取消通話',
            ),
          ),
        ],
      ),
    );
  }
}