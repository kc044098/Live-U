import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'invite_dialog.dart';
import 'mine_invite_page.dart';

class InviteFriendPage extends StatelessWidget {
  const InviteFriendPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('邀请好友',
            style: TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Stack(
        children: [
          // 背景圖
          Positioned.fill(
            child: Image.asset(
              'assets/bg_invite.png',
              fit: BoxFit.fill,
            ),
          ),

          Positioned(
            left: 60,
            top: 20,
            child: const Text(
              '邀请好友',
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEC716C),
              ),
            ),
          ),

          Positioned(
            right: 36,
            top: 30,
            child: Image.asset(
              'assets/invite_pic1.png',
              fit: BoxFit.contain,
            ),
          ),

          Positioned(
            left: 70,
            top: 100,
            child: Image.asset(
              'assets/invite_pic2.png',
              fit: BoxFit.contain,
            ),
          ),

          Positioned(
            right: 40,
            top: 100,
            child: const Text(
              '赚现金',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEC716C),
              ),
            ),
          ),

          Positioned(
            left: 80,
            top: 190,
            child: const Text(
              '- 邀请一次，享终身收益 -',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEC716C),
              ),
            ),
          ),

          // 底部粉紅框 + 內嵌白框
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE6E6),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 白色內框
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding:  const EdgeInsets.fromLTRB(12, 24, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // 紅色 + 白色文案區塊
                            Row(
                              children: [
                                Container(
                                  height: 70,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8888),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    '10%',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 70,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          color: Color(0xFFFF8888), width: 1),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8),
                                        bottomRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Center(
                                      child: const Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '好友每次充值余额，即可享受好友充值总金额',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF535353),
                                                height: 0.8,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '10%',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Color(0xFFFF4D67),
                                                height: 1.4,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '的提成',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF535353),
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 1,
                              child: CustomPaint(
                                painter: DashedLinePainter(),
                                size: const Size(double.infinity, 1),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 按鈕區塊
                            Center(
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (_) => InviteDialog(),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF8888),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    '立即邀请',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            Center(
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const MyInvitePage(),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: Color(0xFFFF8888), width: 1),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    '我的邀请',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFF4D67),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 小標題（輕鬆躺賺）
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/bg_invite_title.svg',
                            height: 28,
                          ),
                          const Text(
                            '·轻松趟赚·',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
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
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  DashedLinePainter({
    this.color = const Color(0xFFFFB6C1), // 粉紅色
    this.dashWidth = 6,
    this.dashSpace = 4,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
