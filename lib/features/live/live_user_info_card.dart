// 首頁 - 首頁 主播資訊的部分元件

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../profile/view_profile_page.dart';

class LiveUserInfoCard extends StatefulWidget {
  final String name;
  final String avatarPath;
  final String rateText;
  final List<String> tags;

  const LiveUserInfoCard({
    super.key,
    required this.name,
    required this.avatarPath,
    required this.rateText,
    required this.tags,
  });

  @override
  State<LiveUserInfoCard> createState() => _LiveUserInfoCardState();
}

class _LiveUserInfoCardState extends State<LiveUserInfoCard> {
  bool isLiked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 頭像 + 綠點
            Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewProfilePage(displayName: widget.name, avatarPath: widget.avatarPath,),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: AssetImage(widget.avatarPath),
                    radius: 24,
                  ),
                ),
                Positioned(
                  bottom: 3,
                  right: 3,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名字 + VIP
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 6),
                        SvgPicture.asset(
                          'assets/live_vip1.svg',
                          width: 36,
                          height: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 金幣圖 + 價格 + 愛心
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/live_gold1.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.rateText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          padding: EdgeInsets.zero,
                          icon: SvgPicture.asset(
                            isLiked
                                ? 'assets/live_heart_filled.svg'
                                : 'assets/live_heart.svg',
                            width: 32,
                            height: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              isLiked = !isLiked;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.tags.map((tag) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}