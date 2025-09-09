import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AutoGrowTextField extends StatefulWidget {
  final TextEditingController controller;
  final TextStyle style;
  final int minChars;          // 起始「字數寬度」
  final double maxFraction;    // 佔用 Row 可用寬度的最大比例（避免擠到按鈕）
  final EdgeInsets padding;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  const AutoGrowTextField({
    required this.controller,
    required this.style,
    this.minChars = 5,
    this.maxFraction = 0.7,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.inputFormatters,
    this.maxLength,
    super.key,
  });

  @override
  State<AutoGrowTextField> createState() => AutoGrowTextFieldState();
}

class AutoGrowTextFieldState extends State<AutoGrowTextField> {
  double _measureTextWidth(String text, double maxWidth) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Row 內可用的上限，預留空間給右側按鈕
        final maxW = c.maxWidth * widget.maxFraction;

        // 量測「最小 5 字」對應的寬度（用 CJK 寬字當基準）
        final minSample = '一' * widget.minChars;
        final minTextW = _measureTextWidth(minSample, maxW);

        // 量測目前文字的寬度
        final current = widget.controller.text;
        final curTextW = _measureTextWidth(current.isEmpty ? ' ' : current, maxW);

        // 加上內距後，做 clamp
        final padW = widget.padding.horizontal;
        final targetW = (curTextW + padW).clamp(minTextW + padW, maxW);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: targetW,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: widget.padding,
          child: TextField(
            controller: widget.controller,
            maxLines: 1,                 // 單行，超過會水平捲動
            style: widget.style,
            inputFormatters: widget.inputFormatters,
            maxLength: widget.maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            decoration: const InputDecoration(
              hintText: '請輸入內容...',
              hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
        );
      },
    );
  }
}
