import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile/profile_controller.dart';

class MessageChatPage extends ConsumerStatefulWidget {
  final String partnerName;
  final String partnerAvatar;
  final bool isVip;
  final String statusText;

  const MessageChatPage({
    super.key,
    required this.partnerName,
    required this.partnerAvatar,
    required this.isVip,
    required this.statusText,
  });

  @override
  ConsumerState<MessageChatPage> createState() => _MessageChatPageState();
}

class _MessageChatPageState extends ConsumerState<MessageChatPage> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 加入初始訊息
    _messages.addAll([
      {
        'isSelf': false,
        'text': '今天有什麼安排？求帶上',
        'isCallMessage': false,
      },
      {
        'isSelf': true,
        'text': '好呀',
        'isCallMessage': false,
      },
      {
        'isSelf': false,
        'text': '今天有什麼安排？求帶上',
        'isCallMessage': false,
      },
      {
        'isSelf': true,
        'text': '好呀',
        'isCallMessage': false,
      },
      {
        'isSelf': true,
        'text': '📞 對方關閉語音接聽',
        'isCallMessage': true,
      },
    ]);
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'isSelf': true,
        'text': text,
        'isCallMessage': false,
      });
    });

    _textController.clear();

    // 自動滾動到底部
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const BackButton(color: Colors.grey),
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(widget.partnerAvatar),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.partnerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    if (widget.isVip)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.purple],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'VIP',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                Text(
                  widget.statusText,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '07/25 10:00',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(
                  isSelf: msg['isSelf'],
                  avatar: msg['isSelf']
                      ? (user?.photoURL ?? '')
                      : widget.partnerAvatar,
                  text: msg['text'],
                  isCallMessage: msg['isCallMessage'] ?? false,
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required bool isSelf,
    required String avatar,
    required String text,
    bool isCallMessage = false,
  }) {
    final bubble = Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: isCallMessage ? Colors.black87 : Colors.black,
        ),
      ),
    );

    return Row(
      mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: isSelf
          ? [
        bubble,
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundImage: avatar.startsWith('http')
              ? NetworkImage(avatar)
              : AssetImage(avatar) as ImageProvider,
          radius: 16,
        ),
      ]
          : [
        CircleAvatar(
          backgroundImage: AssetImage(avatar),
          radius: 16,
        ),
        const SizedBox(width: 8),
        bubble,
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 60,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.2)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: '請輸入消息…',
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                '發送',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}