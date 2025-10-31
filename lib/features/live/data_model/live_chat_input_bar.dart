import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class LiveChatInputBar extends StatelessWidget {
  const LiveChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    this.onTapField,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback? onTapField;

  @override
  Widget build(BuildContext context) {
    final t = S.of(context);
    return SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height:32,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                maxLines: 1,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  onSend();
                  focusNode.unfocus();                         // ← 收鍵盤
                },
                onEditingComplete: () {
                  onSend();
                  focusNode.unfocus();                         // ← 收鍵盤(保險)
                },
                onTap: onTapField,
                onTapOutside: (_) => focusNode.unfocus(),      // ← 點外面也收
                decoration: InputDecoration(
                  hintText: t.liveChatHint,
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
