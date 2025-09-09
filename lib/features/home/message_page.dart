import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../data/models/user_model.dart';
import '../call/call_request_page.dart';
import '../message/chat_providers.dart';
import '../message/chat_repository.dart';
import '../message/chat_thread_item.dart';
import '../message/emoji/emoji_pack.dart';
import '../message/emoji/emoji_text.dart';
import '../message/message_chat_page.dart';
import '../mine/member_fans_provider.dart';
import '../mine/show_like_alert_dialog.dart';
import '../mine/who_likes_me_page.dart';
import '../profile/profile_controller.dart';
import '../wallet/payment_method_page.dart';

class MessagePage extends ConsumerStatefulWidget {
  const MessagePage({super.key});

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends ConsumerState<MessagePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late Future<EmojiPack> _emojiPackFut;

  List<ChatThreadItem> _threads = [];
  bool _loading = true;
  String? _error;
  int _page = 1;

  final List<Tab> _tabs = const [
    Tab(text: '消息'),
    Tab(text: '通話'),
  ];

  final List<Map<String, String>> _callRecords = [
    {
      'avatar': 'assets/pic_girl1.png',
      'name': '漂亮的小姐姐 1',
      'status': '通話時長00:02',
      'type': 'audio', // 'audio' 或 'video'
    },
    {
      'avatar': 'assets/pic_girl2.png',
      'name': '漂亮的小姐姐 2',
      'status': '已取消通話',
      'type': 'video',
    },
    {
      'avatar': 'assets/pic_girl3.png',
      'name': '漂亮的小姐姐 3',
      'status': '未接通',
      'type': 'video',
    },
    {
      'avatar': 'assets/pic_girl4.png',
      'name': '漂亮的小姐姐 4',
      'status': '未接通',
      'type': 'video',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _emojiPackFut = EmojiPack.loadFromFolder('assets/emojis/basic/');

    // ✅ 首次載入「誰喜歡我」資料（非 VIP 才抓）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThreads(page: 1);
      ref.read(memberFansProvider.notifier).loadFirstPage();
    });
  }

  Future<void> _loadThreads({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(chatRepositoryProvider);
      final res = await repo.fetchUserMessageList(page: page);
      setState(() {
        _threads = res.items;
        _page = page;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _onRefresh() => _loadThreads(page: 1);

  int get _totalUnread => _threads.fold(0, (s, it) => s + (it.unread));

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    return Column(
      children: [
        const SizedBox(height: 40),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16),
          tabAlignment: TabAlignment.start,
          tabs: _tabs,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          indicatorColor: Colors.transparent,
          dividerColor: Colors.transparent,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMessageContent( user),
              _buildCallContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent(UserModel? user) {
    final me = user!;

    // 讀誰喜歡我
    final fans = ref.watch(memberFansProvider);
    final int likeCount = fans.totalCount;
    final String? lastName = (fans.items.isNotEmpty) ? fans.items.last.name : null;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('載入失敗：$_error'),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => _loadThreads(page: 1), child: const Text('重試')),
          ],
        ),
      );
    }

    const hasLikeCard = true; // 所有人都顯示
    final totalRows = _threads.length + 1;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: totalRows,
            itemBuilder: (context, index) {
              // 0: 誰喜歡我
              if (hasLikeCard && index == 0) {
                final titleText = '誰喜歡我：有${likeCount > 0 ? likeCount : 0}個人新喜歡';
                final subtitleText = (likeCount > 0 && (lastName != null && lastName.isNotEmpty))
                    ? '[$lastName]  剛喜歡你'
                    : '暫無新喜歡';

                return Column(
                  children: [
                    ListTile(
                      leading: SvgPicture.asset('assets/message_like_1.svg', width: 48, height: 48),
                      title: Text(titleText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Text(subtitleText, style: const TextStyle(color: Colors.grey)),
                      onTap: () async {
                        if (me.isVip == true) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WhoLikesMePage()),
                          );
                          // 回來後刷新一下數字（可選）
                          ref.read(memberFansProvider.notifier).loadFirstPage();
                        } else {
                          showLikeAlertDialog(
                            context,
                            ref,
                                () {},
                            onConfirmWithAmount: (amount) {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => PaymentMethodPage(amount: amount)));
                            },
                          );
                        }
                      },
                    ),
                    const Divider(indent: 20, endIndent: 20),
                  ],
                );
              }

              // 其餘：API 會話列表
              final tIndex = hasLikeCard ? index - 1 : index;
              final it = _threads[tIndex];

              return Column(
                children: [
                  ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(radius: 24, backgroundImage: _avatarOf(me.cdnUrl!, it)),
                        Positioned(
                          bottom: 2, right: 2,
                          child: Container(
                            width: 12, height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(it.status),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      _partnerName(it, me),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: _threadSubtitle(it, me),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end, // ← 只加這行
                      children: [
                        Text(
                          _formatRelative(it.updateAt),
                          textAlign: TextAlign.right,              // ← 建議同步設右對齊
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        if (it.unread > 0)
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Container(
                              width: 20,
                              height: 20,
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(
                                color: Colors.pink,
                                shape: BoxShape.circle,
                              ),
                              child: Text('${it.unread}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      final partnerUid = _partnerUid(it, me);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessageChatPage(
                            partnerName: _partnerName(it, me),
                            partnerAvatar: it.avatars.isNotEmpty ? '${me.cdnUrl}${it.avatars.first}' : 'assets/my_icon_defult.jpeg',
                            vipLevel: it.vip,
                            statusText: it.status,
                            partnerUid: partnerUid,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(indent: 20, endIndent: 20),
                ],
              );
            },
          ),
        ),

        // 底部統計
        Positioned(
          left: 16, right: 16, bottom: 96,
          child: Row(
            children: [
              const Expanded(child: Divider(color: Colors.grey, thickness: 0.5, endIndent: 8)),
              Text('共${_totalUnread}條消息未讀', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Expanded(child: Divider(color: Colors.grey, thickness: 0.5, indent: 8)),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildCallContent() {
    return ListView.builder(
      itemCount: _callRecords.length,
      itemBuilder: (context, index) {
        final call = _callRecords[index];
        final isMissed = call['status'] == '未接通';
        final isCancelled = call['status'] == '已取消通話';

        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: AssetImage(call['avatar']!),
          ),
          title: Text(
            call['name']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            call['status']!,
            style: TextStyle(
              color: isMissed
                  ? Colors.red
                  : (isCancelled ? Colors.grey : Colors.black54),
            ),
          ),
          trailing: SvgPicture.asset(
            call['type'] == 'audio'
                ? 'assets/message_call_1.svg'
                : 'assets/message_call_2.svg',
            width: 32,
            height: 32,
          ),
          onTap: () {
            // 跳轉撥打電話頁面
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CallRequestPage(
                  broadcasterId: 'broadcaster00$index',
                  broadcasterName: call['name']!,
                  broadcasterImage: call['avatar']!,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 顯示：語音就「mic + 秒數」；文字就原文
  Widget _threadSubtitle(ChatThreadItem it, UserModel me) {
    const greyStyle = TextStyle(color: Colors.grey, fontSize: 14);

    // 語音
    if (it.lastIsVoice) {
      final sec = it.lastVoiceDuration;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            (sec != null && sec > 0) ? '${sec}"' : '語音',
            style: greyStyle,
          ),
        ],
      );
    }

    // 👇 圖片
    if (it.lastIsImage) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.image, size: 14, color: Colors.grey),
          SizedBox(width: 4),
          Text('圖片', style: greyStyle),
        ],
      );
    }

    // ✅ 文字
    final t = it.lastText.trim();
    if (t.isNotEmpty) {
      return _subtitleWithEmoji(t);
    }

    if (it.contentRaw.isNotEmpty) {
      try {
        final c = jsonDecode(it.contentRaw);
        if (c is Map) {
          final voicePath = c['voice_path']?.toString() ?? '';
          if (voicePath.isNotEmpty) {
            final d = c['duration'];
            final sec = (d is num) ? d.toInt() : int.tryParse('$d');
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mic, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text((sec != null && sec > 0) ? '${sec}"' : '語音', style: greyStyle),
              ],
            );
          }

          // 👇 新增：圖片兜底解析
          final img = (c['img_path'] ?? c['image_path'])?.toString() ?? '';
          if (img.isNotEmpty) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.image, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text('圖片', style: greyStyle),
              ],
            );
          }
        }
      } catch (_) {}
    }

    // 仍然沒有可顯示內容
    return const Text('…', style: TextStyle(color: Colors.grey));
  }

  String _formatRelative(int epochSec) {
    if (epochSec <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000, isUtc: true).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inHours < 1) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  ImageProvider _avatarOf( String cdnUrl, ChatThreadItem it) {
    // 取第一張頭像；若是相對路徑，用你的檔案域名補上
    if (it.avatars.isNotEmpty) {
      final p = it.avatars.first;
      final url = p.startsWith('http')
          ? p
          : '$cdnUrl$p';
      return NetworkImage(url);
    }
    return const AssetImage('assets/my_icon_defult.jpeg');
  }

  // 判定會話對象（非自己那位）
  int _partnerUid(ChatThreadItem it, UserModel me) {
    final my = int.tryParse(me.uid) ?? -1;
    return it.fromUid == my ? it.toUid : it.fromUid;
  }

  String _partnerName(ChatThreadItem it, UserModel me) {
    // 先用後端給的暱稱，沒有就 fallback
    if ((it.nickname ?? '').isNotEmpty) return it.nickname!;
    final puid = _partnerUid(it, me);
    return '用戶 $puid';
  }

  Widget _subtitleWithEmoji(String text) {
    const style = TextStyle(color: Colors.grey, fontSize: 14);
    return FutureBuilder<EmojiPack>(
      future: _emojiPackFut,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done || snap.data == null) {
          return Text(text, style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
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

  Color _getStatusColor(int index) {
    switch (index) {
      case 1:
      case 2:
        return Colors.green; // 上線
      case 3:
        return Colors.orange; // 忙碌
      default:
        return Colors.grey; // 離線
    }
  }
}
