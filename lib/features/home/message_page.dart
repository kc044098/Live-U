import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../data/models/user_model.dart';
import '../call/call_request_page.dart';
import '../message/message_chat_page.dart';
import '../mine/member_fans_provider.dart';
import '../mine/show_like_alert_dialog.dart';
import '../profile/profile_controller.dart';
import '../wallet/payment_method_page.dart';

class MessagePage extends ConsumerStatefulWidget {
  const MessagePage({super.key});

  @override
  ConsumerState<MessagePage> createState() => _MessagePageState();
}

class _Message {
  final String avatar;
  final String name;
  final String message;
  final String time;
  final int unreadCount;

  _Message({
    required this.avatar,
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
  });
}

class _MessagePageState extends ConsumerState<MessagePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(text: '消息'),
    Tab(text: '通話'),
  ];

  List<_Message> getMessages(UserModel user) {
    final List<_Message> list = [];

    // 非 VIP 才加入「誰喜歡我」
    if (user.isVip != true) {
      list.add(
        _Message(
          avatar: 'assets/message_like_1.svg',
          name: '誰喜歡我',
          message: '[漂亮的小姐姐]  剛喜歡你',
          time: '',
          unreadCount: 0,
        ),
      );
    }

    // 加入其他假訊息
    for (var i = 1; i <= 4; i++) {
      list.add(
        _Message(
          avatar: 'assets/pic_girl$i.png',
          name: '漂亮的小姐姐 $i',
          message: '您好啊',
          time: '一分鐘前',
          unreadCount: 1,
        ),
      );
    }

    return list;
  }

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

    // ✅ 首次載入「誰喜歡我」資料（非 VIP 才抓）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProfileProvider);
      if (user?.isVip != true) {
        ref.read(memberFansProvider.notifier).loadFirstPage();
      }
    });
  }

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
    final messages = getMessages(user!);

    // ✅ 讀取 fans 狀態
    final fans = ref.watch(memberFansProvider);
    // 安全拿 count 與最後一位暱稱
    final int likeCount = fans.totalCount; // 假設你的 state 有 count 欄位（通常會有）
    final String? lastName = (fans.items.isNotEmpty) ? fans.items.last.name : null;

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final item = messages[index];

            Widget tile;
            if (index == 0 && user.isVip == false) {
              // ✅ 動態「誰喜歡我」卡片
              final titleText = '誰喜歡我：有${likeCount > 0 ? likeCount : 0}個人新喜歡';
              final subtitleText = (likeCount > 0 && (lastName != null && lastName.isNotEmpty))
                  ? '[$lastName]  剛喜歡你'
                  : '暫無新喜歡';

              tile = ListTile(
                leading: SvgPicture.asset(
                  item.avatar, // 'assets/message_like_1.svg'
                  width: 48,
                  height: 48,
                ),
                title: Text(
                  titleText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  subtitleText,
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  showLikeAlertDialog(
                    context,
                    ref,
                        () {}, // 舊 onConfirm 保留即可
                    onConfirmWithAmount: (amount) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PaymentMethodPage(amount: amount)),
                      );
                    },
                  );
                },
              );
            } else {
              // 其餘項維持原樣
              tile = ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(item.avatar),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getStatusColor(index),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  '您好啊',
                  style: TextStyle(color: Colors.grey),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.time,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    if (item.unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Colors.pink,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${item.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessageChatPage(
                        partnerName: item.name,
                        partnerAvatar: item.avatar,
                        isVip: true,
                        statusText: '當前在線',
                        partnerUid: 5,
                      ),
                    ),
                  );
                },
              );
            }

            return Column(
              children: [
                tile,
                const Divider(indent: 20, endIndent: 20),
              ],
            );
          },
        ),

        // 底部提示保留
        Positioned(
          left: 16,
          right: 16,
          bottom: 96,
          child: Row(
            children: const [
              Expanded(child: Divider(color: Colors.grey, thickness: 0.5, endIndent: 8)),
              Text('共13條消息未讀', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Expanded(child: Divider(color: Colors.grey, thickness: 0.5, indent: 8)),
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

  Color _getStatusColor(int index) {
    switch (index % 3) {
      case 0:
        return Colors.green; // 上線
      case 1:
        return Colors.orange; // 忙碌
      default:
        return Colors.grey; // 離線
    }
  }

}
