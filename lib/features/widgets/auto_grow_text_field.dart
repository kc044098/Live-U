import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n.dart';

class AutoGrowTextField extends StatefulWidget {
  final TextEditingController controller;
  final TextStyle style;
  final int minChars;
  final double maxFraction;
  final EdgeInsets padding;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  // ⬇️ 新增：是否多行（預設關閉，維持舊行為）
  final bool multiline;

  const AutoGrowTextField({
    required this.controller,
    required this.style,
    this.minChars = 5,
    this.maxFraction = 0.7,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.inputFormatters,
    this.maxLength,
    this.multiline = false, // ⬅️ 預設 false
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
    // ✅ 多行模式：直接用容器撐滿可用寬度，TextField 自動換行
    if (widget.multiline) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: widget.padding,
        child: TextField(
          controller: widget.controller,
          style: widget.style,
          keyboardType: TextInputType.multiline,
          maxLines: null,           // ⬅️ 允許多行
          minLines: 1,
          inputFormatters: widget.inputFormatters,
          maxLength: widget.maxLength,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          decoration: InputDecoration(
            hintText: S.of(context).momentHint1,
            hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            counterText: '',
          ),
        ),
      );
    }

    // ⬇️ 單行舊邏輯（原樣保留）
    return LayoutBuilder(
      builder: (context, c) {
        final maxW = c.maxWidth * widget.maxFraction;
        final minSample = '一' * widget.minChars;
        final minTextW = _measureTextWidth(minSample, maxW);
        final current = widget.controller.text;
        final curTextW = _measureTextWidth(current.isEmpty ? ' ' : current, maxW);
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
            maxLines: 1,
            style: widget.style,
            inputFormatters: widget.inputFormatters,
            maxLength: widget.maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            decoration: InputDecoration(
              hintText: S.of(context).momentHint1,
              hintStyle: const TextStyle(color: Colors.white70, fontSize: 14),
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
