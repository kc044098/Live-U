import 'dart:async';

import 'package:djs_live_stream/features/message/voice_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../data/models/user_model.dart';
import '../call/call_request_page.dart';
import '../profile/profile_controller.dart';
import 'chat_message.dart';

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

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isVoiceMode = false;
  bool _isRecording = false;
  int _recordDuration = 0;
  int _sendCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _messages.addAll([
      ChatMessage(
        type: MessageType.system,
        contentType: ChatContentType.system,
        text: '07/25 10:00',
      ),
      ChatMessage(
        type: MessageType.other,
        contentType: ChatContentType.text,
        text: '今天有什麼安排？求帶上',
        avatar: widget.partnerAvatar,
      ),
      ChatMessage(
        type: MessageType.self,
        contentType: ChatContentType.text,
        text: '好呀',
      ),
    ]);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<String> _getNewAudioPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _startRecording() async {

    // 發送次數超過限制
    if (_sendCount >= 10) {
      _showLimitDialog();
      return;
    }

    if (await _recorder.hasPermission()) {
      final filePath = await _getNewAudioPath();
      await _recorder.start(const RecordConfig(), path: filePath);

      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() => _recordDuration++);
      });
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    _timer?.cancel();

    _sendCount++;

    setState(() {
      _isRecording = false;
    });

    if (path != null) {
      final duration = _recordDuration;
      setState(() {
        _messages.add(ChatMessage(
          type: MessageType.self,
          contentType: ChatContentType.voice,
          audioPath: path,
          duration: duration,
        ));
      });
      _scrollToBottom();
    }
  }

  Future<void> _playAudio(ChatMessage message) async {
    if (message.audioPath == null) return;

    // 停止其他播放
    for (var m in _messages) {
      m.isPlaying = false;
      m.currentPosition = 0;
    }
    setState(() => message.isPlaying = true);

    await _audioPlayer.setFilePath(message.audioPath!);
    _audioPlayer.play();

    // 監聽進度
    _audioPlayer.positionStream.listen((position) {
      if (message.isPlaying) {
        setState(() {
          message.currentPosition = position.inSeconds;
        });
      }
    });

    // 播放完成時
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          message.isPlaying = false;
          message.currentPosition = 0;
        });
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendMessage() {

    // 10 次時觸發彈窗
    if (_sendCount >= 10) {
      _textController.clear();
      _showLimitDialog();
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        type: MessageType.self,
        contentType: ChatContentType.text,
        text: text,
      ));
      _sendCount++;
    });

    _textController.clear();
    _scrollToBottom();
  }

  void _showLimitDialog() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await showDialog(
      context: context,
      barrierDismissible: false, // 點擊背景不關閉
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 上方圖示
                Image.asset('assets/icon_logout_warning.png', width: 100, height: 100),

                const SizedBox(height: 24),

                // 提示文字
                const Text(
                  '當天私信次數已用完，\n您可和她直接視頻通話哦！',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),

                const SizedBox(height: 32),

                // 按鈕 Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 取消按鈕
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => Navigator.pop(context),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.white,
                          ),
                          child: const Center(
                            child: Text(
                              '取消',
                              style: TextStyle(fontSize: 16, color: Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 視頻通話按鈕（漸層）
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          Navigator.pop(context);
                          // 觸發視頻通話
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CallRequestPage(
                                broadcasterId: 'broadcaster001',
                                broadcasterName: widget.partnerName,
                                broadcasterImage: widget.partnerAvatar,
                              ),
                            ),
                          );
                        },
                        child: Ink(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                            ),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam, color: Colors.white, size: 20),
                                SizedBox(width: 6),
                                Text(
                                  '視頻通話',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
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
                return _buildMessageItem(msg, user);
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
                        gradient: const LinearGradient(colors: [Color(0xFFFFA770), Color(0xFFD247FE)]),
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

  Widget _buildMessageItem(ChatMessage message, UserModel? user) {
    if (message.contentType == ChatContentType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(message.text ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      );
    }

    final bool isSelf = message.type == MessageType.self;

    return Row(
      mainAxisAlignment: isSelf ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 對方頭像
        if (!isSelf)
          CircleAvatar(
            radius: 16,
            backgroundImage: widget.partnerAvatar.startsWith('http')
                ? NetworkImage(widget.partnerAvatar)
                : AssetImage(widget.partnerAvatar) as ImageProvider,
          ),
        if (!isSelf) const SizedBox(width: 8),

        _buildBubble(message),

        if (isSelf) const SizedBox(width: 8),
        // 自己頭像（直接用 UserModel 的 avatarImage）
        if (isSelf)
          CircleAvatar(
            radius: 16,
            backgroundImage: user?.avatarImage ?? const AssetImage('assets/my_icon_defult.jpeg'),
          ),
      ],
    );
  }

  Widget _buildBubble(ChatMessage message) {
    switch (message.contentType) {
      case ChatContentType.text:
        return _buildTextBubble(message.text ?? '');
      case ChatContentType.voice:
        return _buildVoiceBubble(message);
      case ChatContentType.call:
        return _buildTextBubble('📞 ${message.text}');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextBubble(String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontSize: 14, color: Colors.black)),
    );
  }

  Widget _buildVoiceBubble(ChatMessage message) {
    return VoiceBubble(
      key: ValueKey('${message.hashCode}-${message.isPlaying}'),
      message: message,
      onPlay: () => _playAudio(message),
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
            icon: Icon(
              _isVoiceMode ? Icons.keyboard_alt_outlined : Icons.mic,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isVoiceMode = !_isVoiceMode;
              });
            },
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _isVoiceMode
                ? GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: _isRecording
                      ? const Color(0xFF4285F4)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _isRecording
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: List.generate(
                          ((_recordDuration - 1) % 5) + 1,
                              (index) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        '${_recordDuration}"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
                    : const Center(
                  child: Text(
                    "按住說話",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ),
              ),
            )
                : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null, // 自動換行
                decoration: const InputDecoration(
                  hintText: '請輸入消息…',
                  hintStyle: TextStyle(color: Colors.black54, fontSize: 14),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
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
}