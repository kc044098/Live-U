import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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
          // 背景圖片 (模糊化處理建議在設計圖或外部處理過)
          Positioned.fill(
            child: Image.asset(
              'assets/bg_calling.png',
              fit: BoxFit.cover,
            ),
          ),
          // 半透明黑色遮罩，讓前景資訊更清楚
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          // 📞 撥號內容 + 滾動適配各種裝置尺寸
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
                      backgroundImage: AssetImage(broadcasterImage),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      broadcasterName,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '等待对方接听...',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 140),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset(
                        'assets/call_end.svg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🔙 關閉按鈕（左上）
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