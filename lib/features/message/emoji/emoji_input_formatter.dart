import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

/// 提供平台分流的 formatter
TextInputFormatter platformEmojiBackspaceFormatter(RegExp tokenReg) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return EmojiBackspaceFixFormatterIOS(tokenReg);
  } else {
    return EmojiBackspaceFixFormatterAndroid(tokenReg);
  }
}

/// 為不同平台附加對應的「游標護欄」
void attachCursorGuardForPlatform(TextEditingController c, RegExp tokenReg) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    _attachCursorGuardIOS(c, tokenReg);
  } else {
    _attachCursorGuardAndroid(c, tokenReg);
  }
}

/// =======================
/// ANDROID 版（沿用你原本的）
/// =======================
class EmojiBackspaceFixFormatterAndroid extends TextInputFormatter {
  final RegExp tokenReg; // r'\[\/([0-9a-fA-F_]+)\]'
  EmojiBackspaceFixFormatterAndroid(this.tokenReg);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {

    // 僅處理「單點退格」
    final isBackspaceOne =
        newValue.selection.isCollapsed &&
            (newValue.text.length + 1 == oldValue.text.length);
    if (!isBackspaceOne) return newValue;

    final oldText  = oldValue.text;
    final oldCaret = oldValue.selection.baseOffset; // 退格前游標
    if (oldCaret <= 0 || oldCaret > oldText.length) return newValue;

    // ANDROID：用 deletedIndex（含右邊界），貼近你舊邏輯
    final deletedIndex = oldCaret - 1;

    final cover = _matchCoveringInclusive(tokenReg, oldText, deletedIndex);
    if (cover != null) {
      final fixedText =
          oldText.substring(0, cover.start) + oldText.substring(cover.end);
      return TextEditingValue(
        text: fixedText,
        selection: TextSelection.collapsed(offset: cover.start),
        composing: TextRange.empty,
      );
    }

    return newValue;
  }

  /// index 落在 [start, end) 視為覆蓋（含邊界 end-1）
  Match? _matchCoveringInclusive(RegExp reg, String text, int index) {
    for (final m in reg.allMatches(text)) {
      // 舊版使用 <= end（或等價於 index < end 但 inclusive 尾端我們也視為在 token）
      if (index >= m.start && index < m.end) return m;
      if (m.start > index) break;
    }
    return null;
  }
}

/// ANDROID 的游標護欄：含右邊界推進
void _attachCursorGuardAndroid(TextEditingController c, RegExp tokenReg) {
  c.addListener(() {
    final v = c.value;
    final sel = v.selection;
    if (!sel.isCollapsed) return;

    final i = sel.baseOffset;
    final text = v.text;
    if (i < 0 || i > text.length) return;

    for (final m in tokenReg.allMatches(text)) {
      // 注意：這裡包含等於 m.end（你的原行為）
      if (i > m.start && i <= m.end) {
        c.value = v.copyWith(
          selection: TextSelection.collapsed(offset: m.end),
          composing: TextRange.empty,
        );
        break;
      }
      if (m.start > i) break;
    }
  });
}

/// ===================
/// iOS 版（嚴格版）
/// ===================
class EmojiBackspaceFixFormatterIOS extends TextInputFormatter {
  final RegExp tokenReg; // r'\[\/([0-9a-fA-F_]+)\]'
  EmojiBackspaceFixFormatterIOS(this.tokenReg);

  bool _isComposing(TextEditingValue v) =>
      v.composing.isValid && !v.composing.isCollapsed;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // iOS：組字期間完全不介入
    if (_isComposing(oldValue) || _isComposing(newValue)) {
      return newValue;
    }

    // 僅處理「單點退格」
    final isBackspaceOne =
        newValue.selection.isCollapsed &&
            (newValue.text.length + 1 == oldValue.text.length);
    if (!isBackspaceOne) return newValue;

    final oldText  = oldValue.text;
    final oldCaret = oldValue.selection.baseOffset; // 退格前游標
    if (oldCaret <= 0 || oldCaret > oldText.length) return newValue;

    // iOS：僅當「退格前游標嚴格在 token 內部」才吞整個 token
    final cover = _matchCoveringStrict(tokenReg, oldText, oldCaret);
    if (cover != null) {
      final fixedText =
          oldText.substring(0, cover.start) + oldText.substring(cover.end);
      return TextEditingValue(
        text: fixedText,
        selection: TextSelection.collapsed(offset: cover.start),
        composing: TextRange.empty,
      );
    }

    return newValue;
  }

  /// 嚴格 inside：start < caret < end（不含邊界）
  Match? _matchCoveringStrict(RegExp reg, String text, int caret) {
    for (final m in reg.allMatches(text)) {
      if (caret > m.start && caret < m.end) return m;
      if (m.start > caret) break;
    }
    return null;
  }
}

/// iOS 的游標護欄：嚴格 inside 才推進（不含邊界）
void _attachCursorGuardIOS(TextEditingController c, RegExp tokenReg) {
  c.addListener(() {
    final v = c.value;

    // 組字期間不動
    if (v.composing.isValid && !v.composing.isCollapsed) return;

    final sel = v.selection;
    if (!sel.isCollapsed) return;

    final i = sel.baseOffset;
    final text = v.text;
    if (i < 0 || i > text.length) return;

    for (final m in tokenReg.allMatches(text)) {
      if (i > m.start && i < m.end) {
        c.value = v.copyWith(
          selection: TextSelection.collapsed(offset: m.end),
          composing: TextRange.empty,
        );
        break;
      }
      if (m.start > i) break;
    }
  });
}
