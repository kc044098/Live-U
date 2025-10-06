import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../message/chat_message.dart';

class LiveChatPanel extends StatelessWidget {
  const LiveChatPanel({
    super.key,
    required this.messages,
    required this.controller,
    required this.myName,
    required this.peerName,
  });

  final List<ChatMessage> messages;
  final ScrollController controller;
  final String myName;
  final String peerName;

  @override
  Widget build(BuildContext context) {
    final panelWidth =
        (MediaQuery.of(context).size.width * 0.6).clamp(220.0, 420.0);
    return SizedBox(
      width: panelWidth,
      height: 380,
      child: ListView.builder(
        controller: controller,
        reverse: true,
        // ✅ 新的在底、貼底
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: messages.length,
        itemBuilder: (_, index) {
          final visualIndex = messages.length - 1 - index; // 由新到舊
          final m = messages[visualIndex];
          final name = (m.type == MessageType.self) ? myName : peerName;

          // 讓泡泡寬度最多到面板寬的 90%，其餘交給文字自動換行
          final maxBubbleWidth = panelWidth * 0.9;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft, // 都靠左顯示（如需左右分邊再改這裡）
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5), // 50% 半透明
                    borderRadius: BorderRadius.circular(20), // 圓角 20
                  ),
                  child: _rowContent(context, m, name),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _rowContent(BuildContext context,ChatMessage m, String name) {
    const nickBlue = Color(0xFF94E1DF);
    final t = S.of(context);

    switch (m.contentType) {
      case ChatContentType.gift:
        final d = m.data ?? const {};
        final icon = (d['gift_icon'] ?? '').toString();
        final title = (d['gift_title'] ?? m.text ?? '').toString();
        final cnt = d['gift_count'] ?? d['count'] ?? 1;
        final count = (cnt is num) ? cnt.toInt() : int.tryParse('$cnt') ?? 1;

        return RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              height: 1.25,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
            children: [
              // 「user 贈送」→ 淡藍色
              TextSpan(
                text: t.giftSend(name),
                style: const TextStyle(
                    color: nickBlue, fontWeight: FontWeight.w600),
              ),
              // 「禮物名」→ 白色、加粗，外面包個書名號
              TextSpan(
                text: '$title ',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              // 禮物 icon → 圖案
              if (icon.isNotEmpty)
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  baseline: TextBaseline.alphabetic,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 1, right: 2),
                    child: Image.network(
                      icon,
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox(width: 18, height: 18),
                    ),
                  ),
                ),
              // 數量
              TextSpan(text: ' x$count'),
            ],
          ),
          softWrap: true,
        );

      default:
        // 其他訊息維持原本樣式
        return Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$name：',
                style: const TextStyle(
                    color: nickBlue, fontWeight: FontWeight.w600),
              ),
              TextSpan(text: m.text ?? ''),
            ],
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white,
            height: 1.25,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
          softWrap: true,
        );
    }
  }
}
