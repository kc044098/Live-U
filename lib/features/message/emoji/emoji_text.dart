// lib/emoji/emoji_text.dart
import 'package:flutter/material.dart';
import 'emoji_pack.dart';

class EmojiText extends StatelessWidget {
  final String text;
  final EmojiPack pack;
  final TextStyle? style;
  final double emojiSize;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;

  const EmojiText(
      this.text, {
        super.key,
        required this.pack,
        this.style,
        this.emojiSize = 18,
        this.textAlign = TextAlign.left,
        this.maxLines,
        this.overflow = TextOverflow.visible,
      });

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    int index = 0;

    for (final m in EmojiPack.tokenReg.allMatches(text)) {
      if (m.start > index) {
        spans.add(TextSpan(text: text.substring(index, m.start)));
      }
      final code = m.group(1)!.toLowerCase();
      final asset = pack.assetOf(code);
      if (asset != null) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Image.asset(asset, width: emojiSize, height: emojiSize),
        ));
      } else {
        // 找不到對應圖片就原樣輸出
        spans.add(TextSpan(text: m.group(0)));
      }
      index = m.end;
    }
    if (index < text.length) {
      spans.add(TextSpan(text: text.substring(index)));
    }

    // 若完全沒有匹配，直接用 Text 顯示（效能更好）
    final hasEmoji = EmojiPack.tokenReg.hasMatch(text);
    if (!hasEmoji) {
      return Text(text, style: style, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
    }

    return RichText(
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      text: TextSpan(style: style ?? const TextStyle(color: Colors.black), children: spans),
    );
  }
}
