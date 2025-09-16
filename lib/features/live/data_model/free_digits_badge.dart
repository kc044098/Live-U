import 'package:flutter/material.dart';

class FreeDigitsBadge extends StatelessWidget {
  final String text; // "MM:SS"
  final Color fg;
  final Color bg;
  const FreeDigitsBadge({required this.text, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    // 拆成 M M : S S
    final mmss = text.padLeft(5, '0'); // 保底 "00:00"
    List<Widget> boxes = [];
    for (int i = 0; i < mmss.length; i++) {
      final ch = mmss[i];
      if (ch == ':') {
        boxes.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(':', style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w700)),
        ));
      } else {
        boxes.add(Container(
          width: 24,
          height: 32,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            ch,
            style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ));
      }
    }
    return SizedBox(              // ★ 撐滿寬度
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // ★ 水平置中
        children: boxes,
      ),
    );
  }
}