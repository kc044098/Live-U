import 'package:flutter/material.dart';

import 'emoji_pack.dart';

class EmojiEditingController extends TextEditingController {
  final EmojiPack pack;
  final double emojiSize;

  EmojiEditingController({required this.pack, this.emojiSize = 18, String? text})
      : super(text: text);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    bool withComposing = false,
  }) {
    final t = value.text;
    final List<InlineSpan> children = [];
    var i = 0;

    for (final m in EmojiPack.tokenReg.allMatches(t)) {
      if (m.start > i) {
        children.add(TextSpan(text: t.substring(i, m.start)));
      }

      final tokenText = t.substring(m.start, m.end); // 例如 [/1f600]
      final code = m.group(1)!.toLowerCase();
      final asset = pack.assetOf(code);

      if (asset != null) {
        // 1) 顯示表情
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.asset(asset, width: emojiSize, height: emojiSize),
          ),
        );
        // 2) 用零寬空白把原本長度補回來（tokenLen - 1）
        final fillerLen = tokenText.length - 1;
        if (fillerLen > 0) {
          children.add(TextSpan(
            text: '\u200B' * fillerLen, // ZERO WIDTH SPACE
            style: const TextStyle(fontSize: 0), // 保守起見，設 0 也可不設
          ));
        }
      } else {
        // 找不到對應表情就原樣顯示代碼
        children.add(TextSpan(text: tokenText));
      }
      i = m.end;
    }

    if (i < t.length) {
      children.add(TextSpan(text: t.substring(i)));
    }

    return TextSpan(style: style, children: children);
  }
}