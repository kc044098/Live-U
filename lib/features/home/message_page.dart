import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../message/message_chat_page.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
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

class _MessagePageState extends State<MessagePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> _plans = [
    {
      'title': '1个月',
      'price': '\$3.99',
      'oldPrice': '',
      'monthly': '3.99美元/月',
    },
    {
      'title': '3个月',
      'price': '\$10.77',
      'oldPrice': '\$11.97',
      'monthly': '10.77美元/月',
    },
    {
      'title': '6个月',
      'price': '\$19.15',
      'oldPrice': '\$23.94',
      'monthly': '19.15美元/月',
    },
    {
      'title': '1年',
      'price': '\$33.5',
      'oldPrice': '\$47.8',
      'monthly': '10.77美元/月',
    },
    {
      'title': '订阅包月',
      'price': '\$9',
      'oldPrice': '\$10',
      'monthly': '9美元/月',
    },
  ];

  final List<Tab> _tabs = const [
    Tab(text: '消息'),
    Tab(text: '通話'),
  ];

  // 假資料：index=0 是固定的誰喜歡我卡片，其餘為訊息列表
  final List<_Message> _messages = List.generate(5, (index) {
    if (index == 0) {
      return _Message(
        avatar: 'assets/message_like_1.svg',
        name: '誰喜歡我',
        message: '[漂亮的小姐姐]  剛喜歡你',
        time: '',
        unreadCount: 0,
      );
    }
    return _Message(
      avatar: 'assets/pic_girl$index.png',
      name: '漂亮的小姐姐 $index',
      message: '您好啊',
      time: '一分鐘前',
      unreadCount: 1,
    );
  });

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              _buildMessageContent(),
              _buildCallContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageContent() {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(bottom: 120),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final item = _messages[index];

            Widget tile;
            if (index == 0) {
              // 固定「誰喜歡我」卡片
              tile = ListTile(
                leading: SvgPicture.asset(
                  item.avatar,
                  width: 48,
                  height: 48,
                ),
                title: const Text(
                  '誰喜歡我：有43個人新喜歡',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Text(
                  item.message,
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: _showLikeAlertDialog,
              );
            } else {
              // 普通訊息卡片
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
                          color: _getStatusColor(index), // ✅ 根據狀態改顏色
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
                subtitle: Text(
                  item.message,
                  style: const TextStyle(color: Colors.grey),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Colors.pink,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${item.unreadCount}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
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
                        isVip: true, // 假設全部是 VIP，用條件決定也可
                        statusText: '當前在線', // 可依需要傳不同文字
                      ),
                    ),
                  );
                },
              );
            }

            // 回傳含分隔線的組件
            return Column(
              children: [
                tile,
                const Divider(
                  indent: 20,
                  endIndent: 20,
                ),
              ],
            );
          },
        ),

        // 底部提示
        Positioned(
          left: 16,
          right: 16,
          bottom: 96,
          child: Row(
            children: [
              const Expanded(
                child: Divider(
                  color: Colors.grey,
                  thickness: 0.5,
                  endIndent: 8,
                ),
              ),
              const Text(
                '共13條消息未讀',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Expanded(
                child: Divider(
                  color: Colors.grey,
                  thickness: 0.5,
                  indent: 8,
                ),
              ),
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
            // TODO: 點擊通話記錄
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

  void _showLikeAlertDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFC3C3), Color(0xFFFFEFEF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // 右上角圖片
                Positioned(
                  top: 0,
                  right: 0,
                  child: Image.asset(
                    'assets/message_like_2.png',
                    width: 60,
                    height: 60,
                  ),
                ),
                // 主內容
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '誰喜歡我',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        '查看對你心動的Ta，立即聯繫不再等待',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Color(0xfffb5d5d)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    getSubscriptionPlan(),
                    const SizedBox(height: 10),
                    Center(
                      child: SizedBox(
                        width: 180,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('去充值'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget getSubscriptionPlan() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _plans.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final plan = _plans[index];
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                plan['title']!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              if (plan['oldPrice']!.isNotEmpty) ...[
                Text(
                  plan['oldPrice']!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                plan['price']!,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                plan['monthly']!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}
