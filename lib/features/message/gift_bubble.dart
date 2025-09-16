import 'package:flutter/material.dart';

class GiftBubble extends StatelessWidget {
  const GiftBubble({
    super.key,
    required this.title,
    required this.count,
    required this.iconUrl,
    this.isSelf = true,
  });

  final String title;
  final int count;
  final String iconUrl;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final textColor = isSelf ? Colors.white : Colors.black87;
    final bg = isSelf ? const Color(0xFF6C4DD8) : const Color(0xFFF5F5F5);

    Widget giftIcon() {
      if (iconUrl.isEmpty) {
        return const SizedBox(width: 24, height: 24);
      }
      return Image.network(iconUrl, width: 24, height: 24, fit: BoxFit.cover);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Color(0xFF86E5FF), Color(0xFFC2F2FF)],
            ).createShader(r),
            child: const Text('贈送', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          giftIcon(),
          const SizedBox(width: 6),
          Text('x $count', style: TextStyle(color: textColor)),
        ],
      ),
    );
  }
}
