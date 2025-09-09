import 'package:flutter/services.dart';

import 'package:characters/characters.dart';

import 'package:flutter/services.dart';
import 'package:characters/characters.dart';

class EmojiBackspaceFixFormatter extends TextInputFormatter {
  final RegExp tokenReg; // r'\[\/([0-9a-fA-F_]+)\]'
  EmojiBackspaceFixFormatter(this.tokenReg);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 只處理「單點退格」
    if (!(newValue.selection.isCollapsed &&
        newValue.text.length < oldValue.text.length)) {
      return newValue;
    }

    final oldText   = oldValue.text;
    final oldCaret  = oldValue.selection.baseOffset; // 退格前游標
    if (oldCaret <= 0 || oldCaret > oldText.length) return newValue;

    final deletedIndex = oldCaret - 1; // 被刪掉的字元索引（在 oldText 裡）

    // 1) 若刪除點在某個 token 內 → 一次刪整個 token
    final m = _matchCovering(tokenReg, oldText, deletedIndex);
    if (m != null) {
      final fixed = oldText.substring(0, m.start) + oldText.substring(m.end);
      return TextEditingValue(
        text: fixed,
        selection: TextSelection.collapsed(offset: m.start),
        composing: TextRange.empty,
      );
    }

    // 2) 否則 → 正常刪 1 個「字素」（正確刪中文字/emoji/合字）
    final left  = oldText.substring(0, oldCaret).characters;
    final right = oldText.substring(oldCaret);
    if (left.isEmpty) return newValue;

    final leftFixed = left.skipLast(1).toString();
    final fixed = leftFixed + right;
    return TextEditingValue(
      text: fixed,
      selection: TextSelection.collapsed(offset: leftFixed.length),
      composing: TextRange.empty,
    );
  }

  // 傳回涵蓋 index 的 token match（若無則 null）
  Match? _matchCovering(RegExp reg, String text, int index) {
    for (final m in reg.allMatches(text)) {
      if (index >= m.start && index < m.end) return m;
      if (m.start > index) break;
    }
    return null;
  }
}