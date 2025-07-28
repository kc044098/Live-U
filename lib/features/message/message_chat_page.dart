import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile/profile_controller.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();

    _messages.addAll([
      ChatMessage(type: MessageType.system, text: '07/25 10:00'),
      ChatMessage(
          type: MessageType.other,
          text: '今天有什麼安排？求帶上',
          avatar: widget.partnerAvatar),
      ChatMessage(type: MessageType.self, text: '好呀'),
    ]);
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) => debugPrint('Speech status: $status'),
        onError: (error) => debugPrint('Speech error: $error'),
      );

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: 'zh-TW', // 或 'zh-CN', 'en-US'
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
              _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length),
              );
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(type: MessageType.self, text: text));
    });

    _textController.clear();
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
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageItem(msg, user?.photoURL ?? '');
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          const BackButton(color: Colors.grey),
          CircleAvatar(radius: 20, backgroundImage: AssetImage(widget.partnerAvatar)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(widget.partnerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  if (widget.isVip)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.orange, Colors.purple]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('VIP', style: TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                ],
              ),
              Text(widget.statusText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
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
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.grey),
            onPressed: _listen,
          ),
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
                gradient: const LinearGradient(colors: [Colors.orange, Colors.purple]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text('發送', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message, String selfAvatar) {
    switch (message.type) {
      case MessageType.system:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Text(
              message.text,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        );

      case MessageType.other:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(message.avatar ?? ''),
              radius: 16,
            ),
            const SizedBox(width: 8),
            _buildBubble(message),
          ],
        );

      case MessageType.self:
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBubble(message),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundImage: selfAvatar.startsWith('http')
                  ? NetworkImage(selfAvatar)
                  : AssetImage(selfAvatar) as ImageProvider,
              radius: 16,
            ),
          ],
        );
    }
  }

  Widget _buildBubble(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: message.isCallMessage ? Colors.grey[200] : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message.text,
        style: TextStyle(
          fontSize: 14,
          color: message.isCallMessage ? Colors.black87 : Colors.black,
        ),
      ),
    );
  }

}

enum MessageType {
  self,    // 自己發送
  other,   // 對方發送
  system,  // 系統訊息
}

class ChatMessage {
  final MessageType type;
  final String text;
  final String? avatar;  // 只有 user 類型消息才會有頭像
  final bool isCallMessage;

  ChatMessage({
    required this.type,
    required this.text,
    this.avatar,
    this.isCallMessage = false,
  });
}