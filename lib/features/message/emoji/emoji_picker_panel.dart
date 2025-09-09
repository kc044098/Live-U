// lib/emoji/emoji_picker_panel.dart
import 'package:flutter/material.dart';
import 'emoji_pack.dart';

class EmojiPickerPanel extends StatelessWidget {
  final EmojiPack pack;
  final ValueChanged<String> onSelected; // 會回傳 token，例：[/1f600]
  final double itemSize;

  const EmojiPickerPanel({
    super.key,
    required this.pack,
    required this.onSelected,
    this.itemSize = 44,
  });

  @override
  Widget build(BuildContext context) {
    final codes = pack.codes.toList()..sort();
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8, mainAxisSpacing: 8, crossAxisSpacing: 8,
      ),
      itemCount: codes.length,
      itemBuilder: (_, i) {
        final code = codes[i];
        final asset = pack.assetOf(code)!;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => onSelected(pack.tokenFor(code)),
          child: Center(child: Image.asset(asset, width: itemSize, height: itemSize)),
        );
      },
    );
  }
}