import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../data/models/gift_item.dart';
import '../../l10n/l10n.dart';
import '../widgets/cached_network_image.dart';
import 'emoji/emoji_pack.dart';
import 'emoji/emoji_text.dart';

class InboxMessageBanner extends StatelessWidget {
  final String title;
  final String avatarUrl;
  final VoidCallback onReply;

  // 舊參數：若給了就顯示文字；否則走 content 樣式化
  final String? preview;

  // 新參數：直接餵 WS 的 content（如 {"chat_text":"...","img_path":"..."}）
  final String? previewContent;
  final String? cdnBase;
  final List<GiftItemModel> gifts;

  const InboxMessageBanner({
    super.key,
    required this.title,
    required this.avatarUrl,
    required this.onReply, // ✅ 回覆按鈕不可省略
    this.preview,
    this.previewContent,
    this.cdnBase,
    this.gifts = const [],
  });

  static final Future<EmojiPack> _emojiPackFut =
      EmojiPack.loadFromFolder('assets/emojis/basic/');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    const subtitleStyle = TextStyle(color: Colors.black54, fontSize: 12);

    // 先得到「核心預覽」(不含前綴)
    final Widget corePreview =
        (previewContent != null && previewContent!.isNotEmpty)
            ? _buildPreviewFromContent(
                context: context,
                content: previewContent!,
                cdn: cdnBase ?? '',
                gifts: gifts,
                style: subtitleStyle,
                emojiPackFuture: _emojiPackFut,
              )
            : Text(
                preview ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: subtitleStyle,
              );

    // ✅ 統一加上「私信了你：」前綴
    final Widget prefixedPreview = Row(
      children: [
        Text(s.dmPrefix, style: subtitleStyle),
        const SizedBox(width: 2),
        Expanded(child: corePreview),
      ],
    );

    final top = MediaQuery.of(context).padding.top;
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(top: top > 0 ? 6 : 12, left: 12, right: 12),
          child: Material(
            elevation: 8,
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 76,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      buildAvatarCircle(url: avatarUrl, radius: 22),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: SvgPicture.asset(
                          'assets/pic_message_send.svg',
                          width: 18,
                          height: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        prefixedPreview, // 👈 這裡會帶前綴
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ✅ 回覆按鈕保留且必顯示
                  SizedBox(
                    height: 38,
                    child: Material(
                      color: Colors.transparent,
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            debugPrint('📬[Banner] reply tapped');
                            onReply();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            child: Text(
                              s.replyAction,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // === 樣式化預覽：禮物 / 圖片 / 語音 / 文字 ===
  static Widget _buildPreviewFromContent({
    required BuildContext context,
    required String content,
    required String cdn,
    required List<GiftItemModel> gifts,
    required TextStyle style,
    Future<EmojiPack>? emojiPackFuture,
  }) {
    final s = S.of(context);
    Map<String, dynamic>? _json(String? s) {
      if (s == null || s.isEmpty) return null;
      try {
        final v = jsonDecode(s);
        if (v is Map) return v.map((k, v) => MapEntry(k.toString(), v));
      } catch (_) {}
      return null;
    }

    int? _i(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v');
    String _full(String base, String p) {
      if (p.isEmpty || p.startsWith('http')) return p;
      final b = base.replaceFirst(RegExp(r'/+$'), '');
      final q = p.replaceFirst(RegExp(r'^/+'), '');
      return '$b/$q';
    }

    final outer = _json(content) ?? const <String, dynamic>{};
    final chatTxt = (outer['chat_text'] ?? '').toString();
    final imgPath = (outer['img_path'] ?? outer['image_path'] ?? '').toString();
    final voice = (outer['voice_path'] ?? '').toString();
    final durSec = _i(outer['duration']) ?? 0;

    // 禮物（chat_text 還有一層）
    final gift = _json(chatTxt);
    final giftType = (gift?['type'] ?? gift?['t'])?.toString().toLowerCase();
    if (gift != null && giftType == 'gift') {
      final id = _i(gift['gift_id'] ?? gift['id']) ?? -1;
      String title = (gift['gift_title'] ?? gift['title'] ?? '').toString();
      String iconRel = (gift['gift_icon'] ?? gift['icon'] ?? '').toString();
      final count = _i(gift['gift_count'] ?? gift['count'] ?? 1) ?? 1;

      if ((title.isEmpty || iconRel.isEmpty) && id >= 0) {
        final m = gifts.where((g) => g.id == id);
        if (m.isNotEmpty) {
          title = title.isEmpty ? m.first.title : title;
          iconRel = iconRel.isEmpty ? m.first.icon : iconRel;
        }
      }
      final iconFull = _full(cdn, iconRel);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.card_giftcard, size: 14, color: Colors.black45),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              title.isNotEmpty ? '${s.giftShort} · $title' : s.giftShort,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (iconFull.isNotEmpty) ...[
            const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.network(iconFull,
                  width: 14, height: 14, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(width: 6),
          Text(s.xCount(count), style: style),
        ],
      );
    }

    // 圖片
    if (imgPath.isNotEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image, size: 14, color: Colors.black45),
          const SizedBox(width: 4),
          Flexible(
            child: Text(s.imageShort, style: style, overflow: TextOverflow.ellipsis),
          ),
        ],
      );
    }

    // 語音
    if (voice.isNotEmpty) {
      final label = (durSec > 0) ? s.voiceWithSeconds(durSec) : s.voiceShort;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, size: 14, color: Colors.black45),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label, style: style, overflow: TextOverflow.ellipsis),
          ),
        ],
      );
    }

    // 文字
    final raw = (chatTxt.isNotEmpty ? chatTxt : content).trim();
    final fallback = s.incomingGenericMessage;
    if (emojiPackFuture == null) {
      return Text(
        raw.isNotEmpty ? raw : fallback,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return FutureBuilder<EmojiPack>(
      future: emojiPackFuture,
      builder: (context, snap) {
        final text = raw.isNotEmpty ? raw : fallback;
        if (snap.connectionState != ConnectionState.done || snap.data == null) {
          return Text(
            text,
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }
        return EmojiText(
          text,
          pack: snap.data!,
          style: style,
          emojiSize: 16,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
