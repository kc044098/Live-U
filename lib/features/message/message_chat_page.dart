import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:djs_live_stream/features/message/voice_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../data/models/user_model.dart';
import '../call/call_request_page.dart';
import '../mine/user_repository_provider.dart';
import '../profile/profile_controller.dart';
import 'chat_utils.dart' as cu;
import 'chat_message.dart';
import 'chat_providers.dart';
import 'chat_ws_service.dart';
import 'emoji/emoji_editing_controller.dart';
import 'emoji/emoji_input_formatter.dart';
import 'emoji/emoji_pack.dart';
import 'emoji/emoji_picker_panel.dart';
import 'emoji/emoji_text.dart';

class MessageChatPage extends ConsumerStatefulWidget {
  final String partnerName;
  final String partnerAvatar;
  final int vipLevel;
  final int statusText;

  final int? partnerUid;

  const MessageChatPage({
    super.key,
    required this.partnerName,
    required this.partnerAvatar,
    required this.vipLevel,
    required this.statusText,
    this.partnerUid,
  });

  @override
  ConsumerState<MessageChatPage> createState() => _MessageChatPageState();
}

class _MessageChatPageState extends ConsumerState<MessageChatPage> {
  final List<ChatMessage> _messages = [];
  late TextEditingController _textController;
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshCtrl = RefreshController(initialRefresh: false);

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<VoidCallback> _wsUnsubs = [];

  late Future<EmojiPack> _emojiPackFut;
  bool _showEmoji = false;

  bool _isVoiceMode = false;
  bool _isRecording = false;
  int _recordDuration = 0;
  int _sendCount = 0;
  Timer? _timer;

  bool _isLoadingMore = false;
  bool _loading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  late VoidCallback _wsUnsubRoomChat;
  late VoidCallback _wsUntapRaw;

  late final FocusNode _inputFocus;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();

    _attachCursorGuard(_textController);

    // 表情面板監聽輸入焦點
    _inputFocus = FocusNode();
    _inputFocus.addListener(() {
      if (_inputFocus.hasFocus && _showEmoji) {
        setState(() => _showEmoji = false);
        _scrollToBottom();
      }
    });
    _emojiPackFut = EmojiPack.loadFromFolder('assets/emojis/basic/').then((pack) {
      final old = _textController;
      _textController = EmojiEditingController(pack: pack, emojiSize: 18, text: old.text)
        ..selection = old.selection;
      old.dispose();
      _attachCursorGuard(_textController);
      setState(() {});      // 讓 TextField 重建後就能顯示圖片
      return pack;
    });
    _refreshHistory();
  }

  Future<void> _refreshHistory() async {
    if (widget.partnerUid == null) return;
    setState(() { _loading = true; _error = null; _hasMore = true; _page = 1; });

    try {
      final me = ref.read(userProfileProvider);
      final myUid = int.tryParse(me?.uid ?? '') ?? -1;
      final repo = ref.read(chatRepositoryProvider);
      final list = await repo.fetchMessageHistory(page: 1, toUid: widget.partnerUid!);
      final cdnBase = me?.cdnUrl ?? '';

      final msgs = list.map((m) =>
          _fromApiMsg(Map<String, dynamic>.from(m), myUid: myUid, cdnBase: cdnBase)
      ).toList()
        ..sort((a, b) => (a.createAt ?? 0).compareTo(b.createAt ?? 0)); // 舊→新

      setState(() {
        _messages
          ..clear()
          ..addAll(msgs);
        _loading = false;
        _hasMore = list.isNotEmpty; // 簡單判斷；你也可依 API 回傳是否還有下一頁
        _page = 1;
      });
      _refreshCtrl.resetNoData();
      _refreshCtrl.loadComplete();
      _scrollToBottom(); // 最新貼底
    } catch (e) {
      setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<int> _loadOlderPage() async {
    if (widget.partnerUid == null || _isLoadingMore || !_hasMore) return 0;
    setState(() => _isLoadingMore = true);

    final beforeMax = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;

    int inserted = 0;

    try {
      final me = ref.read(userProfileProvider);
      final myUid = int.tryParse(me?.uid ?? '') ?? -1;
      final cdnBase = me?.cdnUrl ?? '';
      final repo = ref.read(chatRepositoryProvider);

      final nextPage = _page + 1;
      final list = await repo.fetchMessageHistory(page: nextPage, toUid: widget.partnerUid!);

      final older = list.map((m) =>
          _fromApiMsg(Map<String, dynamic>.from(m), myUid: myUid, cdnBase: cdnBase)
      ).toList()
        ..sort((a, b) => (a.createAt ?? 0).compareTo(b.createAt ?? 0));

      bool _dup(ChatMessage x) => _messages.any((y) =>
      (y.createAt == x.createAt) &&
          (y.contentType == x.contentType) &&
          ((y.text ?? '') == (x.text ?? '')) &&
          ((y.audioPath ?? '') == (x.audioPath ?? '')) &&
          ((y.imagePath ?? '') == (x.imagePath ?? '')) &&
          (y.type == x.type));

      final toInsert = older.where((e) => !_dup(e)).toList();
      inserted = toInsert.length;

      if (inserted > 0) {
        setState(() {
          _messages.insertAll(0, toInsert); // 把更舊的插到最前
          _page = nextPage;
        });

        // ⭐ 反轉列表的正確「不跳動」位移補償
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          final afterMax = _scrollController.position.maxScrollExtent;
          final delta = afterMax - beforeMax;
          if (delta > 0) {
            // reverse=true 時維持相同項目可見：pixels += delta
            _scrollController.jumpTo(_scrollController.position.pixels + delta);
          }
        });
      } else {
        // 這頁完全沒有新內容（重複或空），視為沒有更多
        setState(() {
          _hasMore = false;
          _page = nextPage;
        });
      }

      if (list.isEmpty) {
        setState(() => _hasMore = false);
      }
    } catch (e) {
      debugPrint('load older fail: $e');
      rethrow;
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }

    return inserted;
  }

  void _attachCursorGuard(TextEditingController c) {
    c.addListener(() {
      final sel = c.selection;
      if (!sel.isCollapsed) return;
      final i = sel.baseOffset;
      if (i < 0 || i > c.text.length) return;

      for (final m in EmojiPack.tokenReg.allMatches(c.text)) {
        if (i > m.start && i <= m.end) {
          // 游標在 token 內部 → 推到 token 後
          c.selection = TextSelection.collapsed(offset: m.end);
          break;
        }
      }
    });
  }

  @override
  void dispose() {
    for (final u in _wsUnsubs) { try { u(); } catch (_) {} }
    try { _wsUnsubRoomChat(); } catch (_) {}
    try { _wsUntapRaw(); } catch (_) {}
    _inputFocus.dispose();
    _timer?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    _textController.dispose();
    super.dispose();
  }

  Widget _buildListView() {
    final list = ListView.builder(
      controller: _scrollController,
      reverse: true, // 最新在下（offset=0）
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      physics: const BouncingScrollPhysics(), // 視覺手感好一點
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final visualIndex = _messages.length - 1 - index; // 由新到舊
        final msg = _messages[visualIndex];
        return Column(
          children: [
            if (_shouldShowTime(visualIndex))
              _timeLabel(_formatChatTime(msg.createAt ?? 0)),
            _buildMessageItem(msg, ref.watch(userProfileProvider)),
          ],
        );
      },
    );

    return SmartRefresher(
      controller: _refreshCtrl,
      enablePullDown: false,        // 不用下拉重整整頁（保證不會被它捲動）
      enablePullUp: _hasMore,       // 用「上拉載入」取得更舊訊息（對 reverse 來說是滾到頂）
      onLoading: _onSmartLoadOlder, // 到頂觸發
      footer: ClassicFooter(
        idleText: '上拉載入更多',
        canLoadingText: '釋放以載入更多',
        loadingText: '載入中…',
        noDataText: '已顯示最舊的消息',
      ),
      child: list,
    );
  }

  Future<void> _onSmartLoadOlder() async {
    try {
      final inserted = await _loadOlderPage();
      if (inserted == 0 || !_hasMore) {
        _refreshCtrl.loadNoData();      // 顯示「已顯示最舊的消息」，並停用上拉
      } else {
        _refreshCtrl.loadComplete();
      }
    } catch (_) {
      _refreshCtrl.loadFailed();
    }
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
    if (!_isRecording) return;                // ✅ 避免重入
    final path = await _recorder.stop();
    _timer?.cancel();
    setState(() => _isRecording = false);
    if (path == null) return;

    _sendCount++;

    // 取得 myUid / toUid
    final user  = ref.read(userProfileProvider);
    final myUid = int.tryParse(user?.uid ?? '');
    final toUid = widget.partnerUid;

    if (myUid == null || toUid == null) {
      // ❌ 不能發送時，保留本地檔播放，標記失敗即可（不要把本地檔拼 CDN）
      setState(() {
        _messages.add(ChatMessage(
          type: MessageType.self,
          contentType: ChatContentType.voice,
          audioPath: path,                     // ✅ 本地檔
          duration: _recordDuration,
          sendState: SendState.failed,
        ));
      });
      _scrollToBottom();
      return;
    }

    final uuid = cu.genUuid(myUid);

    // 1) 樂觀加入一條「語音・傳送中」（先用本地檔，立即可播）
    final optimistic = ChatMessage(
      type: MessageType.self,
      contentType: ChatContentType.voice,
      audioPath: path,                         // ✅ 本地檔，立即可播
      duration: _recordDuration,
      uuid: uuid,
      flag: 'chat_person',
      toUid: toUid,
      sendState: SendState.sending,
      createAt: cu.nowSec(),
    );
    setState(() => _messages.add(optimistic));
    _scrollToBottom();

    final chatRepo = ref.read(chatRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    try {
      // 2) 上傳到 S3，拿「相對路徑」
      final rel = await userRepo.uploadToS3(file: File(path)); // e.g. /upload/xxx.m4a
      final full = cu.joinCdn(user?.cdnUrl, rel);                // ✅ UI 播放用完整 URL

      // 3) 發送語音消息：後端要相對路徑
      final ok = await chatRepo.sendVoice(
        uuid: uuid,
        toUid: toUid,
        voicePath: rel,                         // ✅ 傳相對路徑給後端
        durationSec: _recordDuration.toString(),
      );

      if (!mounted) return;
      setState(() {
        final i = _messages.indexWhere((m) => m.uuid == uuid);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(
            sendState: ok ? SendState.sent : SendState.failed,
            audioPath: ok ? full : path,        // ✅ 成功→用 CDN 完整 URL；失敗→保留本地
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final i = _messages.indexWhere((m) => m.uuid == uuid);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(
            sendState: SendState.failed,
            audioPath: path,                    // 失敗保留本地檔可重播
          );
        }
      });
    }
  }

  Future<void> _playAudio(ChatMessage message) async {
    final p = message.audioPath;
    if (p == null) return;

    for (var m in _messages) {
      m.isPlaying = false;
      m.currentPosition = 0;
    }
    setState(() => message.isPlaying = true);

    if (p.startsWith('http')) {
      await _audioPlayer.setUrl(p);
    } else {
      await _audioPlayer.setFilePath(p);
    }
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

  // 2) 捲到底：reverse 後「底部」就是 offset=0
  void _scrollToBottom({bool force = false}) {
    if (!force && _isLoadingMore) return; // ⭐ 載舊過程不自動跳
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
          0.0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  void _sendMessage() async {
    if (_sendCount >= 10) {
      _textController.clear();
      _showLimitDialog();
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 取得 myUid 與 對方 uid
    final user = ref.read(userProfileProvider);
    final myUid = int.tryParse(user?.uid ?? '');
    final toUid = widget.partnerUid; // 或使用你本頁現有變數

    // 若取不到 id，避免打 API，但仍可把訊息顯示為失敗（不破 UI）
    if (myUid == null || toUid == null) {
      setState(() {
        _messages.add(ChatMessage(
          type: MessageType.self,
          contentType: ChatContentType.text,
          text: text,
          sendState: SendState.failed,
        ));
        _sendCount++;
        _showEmoji = false;
      });
      _textController.clear();
      _scrollToBottom();
      return;
    }

    final uuid = cu.genUuid(myUid);

    // 樂觀加入一條 sending 訊息
    final sending = ChatMessage(
      type: MessageType.self,
      contentType: ChatContentType.text,
      text: text,
      uuid: uuid,
      flag: 'chat_person',
      toUid: toUid,
      data: {'chat_text': text},
      sendState: SendState.sending,
      createAt: cu.nowSec(),
    );
    setState(() {
      _messages.add(sending);
      _sendCount++;
      _showEmoji = false;
    });
    _textController.clear();
    _scrollToBottom();

    // ✅ 呼叫 Repository
    final repo = ref.read(chatRepositoryProvider);
    final ok = await repo.sendText(uuid: uuid, toUid: toUid, text: text);

    if (!mounted) return;
    setState(() {
      final i = _messages.indexWhere((m) => m.uuid == uuid);
      if (i >= 0) {
        _messages[i] = _messages[i].copyWith(
          sendState: ok ? SendState.sent : SendState.failed,
        );
      }
    });
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
                  '当天私信次数已用完，\n您可和她直接视频通话哦！',
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

  ChatMessage _fromApiMsg(
      Map<String, dynamic> m, {
        required int myUid,
        required String cdnBase,
      }) {
    final senderUid   = (m['uid'] as num?)?.toInt() ?? -1;
    final rawContent  = (m['content'] ?? '').toString();
    final createAt   = _parseEpochSec(m['create_at']);

    Map<String, dynamic>? c;
    try {
      final tmp = jsonDecode(rawContent);
      if (tmp is Map) c = tmp.map((k, v) => MapEntry('$k', v));
    } catch (_) { /* 不是 JSON 就保持 null */ }

    final voicePathRel = c?['voice_path']?.toString();
    final chatText     = c?['chat_text']?.toString();
    final duration     = int.parse(c?['duration'] ?? '0');
    final imgPathRel   = (c?['img_path'] ?? c?['image_path'])?.toString();

    // 圖片
    if ((imgPathRel ?? '').isNotEmpty) {
      final full = cu.joinCdn(cdnBase, imgPathRel!);
      return ChatMessage(
        type: senderUid == myUid ? MessageType.self : MessageType.other,
        contentType: ChatContentType.image,
        imagePath: full,
        createAt: createAt,
      );
    }

    // 語音
    if ((voicePathRel ?? '').isNotEmpty) {
      final full = cu.joinCdn(cdnBase, voicePathRel!); // 顯示用拼 CDN
      return ChatMessage(
        type: senderUid == myUid ? MessageType.self : MessageType.other,
        contentType: ChatContentType.voice,
        audioPath: full,
        duration: duration,
        createAt: createAt,
      );
    }

    // 文字
    return ChatMessage(
      type: senderUid == myUid ? MessageType.self : MessageType.other,
      contentType: ChatContentType.text,
      text: (chatText != null && chatText.isNotEmpty) ? chatText : rawContent,
      createAt: createAt,
    );
  }

  int _parseEpochSec(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final partnerUid = widget.partnerUid;
    if (partnerUid != null) {
      ref.listen<AsyncValue<ChatMessage>>(
        roomChatProvider(partnerUid),
            (prev, next) {
          next.whenData((msg) {
            if (!mounted) return;
            setState(() => _messages.add(msg));
            final atBottom = !_scrollController.hasClients
                || _scrollController.position.pixels <= 40;
            if (atBottom) _scrollToBottom();
          });
        },
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('載入失敗：$_error'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _refreshHistory,
                    child: const Text('重試'),
                  ),
                ],
              ),
            )
                : _buildListView(),
          ),
          _buildInputBar(),
          if (_showEmoji)
            SizedBox(
              height: 260,
              child: FutureBuilder<EmojiPack>(
                future: _emojiPackFut,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done || snap.data == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return EmojiPickerPanel(
                    pack: snap.data!,
                    onSelected: (token) => _insertAtCursor(token),
                  );
                },
              ),
            ),

          _buildBottomActions(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: const BackButton(color: Colors.grey),
      titleSpacing: 0,                   // 避免左側空太大（可留可去）
      title: Row(
        mainAxisSize: MainAxisSize.min,  // ✅ 讓 Title 寬度貼內容，方便置中
        children: [
          Stack(
            children: [
              CircleAvatar(radius: 24, backgroundImage: _avatar()),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(widget.statusText),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.partnerName,
                    style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  if (widget.vipLevel != 0)
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
              const SizedBox(height: 2),
              Text(_presenceLabel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 對方頭像
        if (!isSelf)
          CircleAvatar(
            radius: 16,
            backgroundImage: _avatar(),
          ),
        if (!isSelf) const SizedBox(width: 8),

        // 訊息氣泡
        _buildBubble(message),

        if (isSelf) const SizedBox(width: 6),
        if (isSelf) _tailStatus(message),
        if (isSelf) const SizedBox(width: 8),

        if (isSelf)
          CircleAvatar(
            radius: 16,
            backgroundImage: user?.avatarImage ?? const AssetImage('assets/my_icon_defult.jpeg'),
          ),
      ],
    );
  }

  Widget _buildBottomActions() {
    final items = <Map<String, dynamic>>[
      {'icon': 'assets/message_icon_1.svg', 'label': '表情', 'onTap': () {
        _toggleEmojiPanel();
      }},
      {'icon': 'assets/message_icon_2.svg', 'label': '通話', 'onTap': () {
        final isBusy = widget.statusText == 3; // 頁面裡的 3=忙線中
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallRequestPage(
              broadcasterId: (widget.partnerUid ?? -1).toString(),
              broadcasterName: widget.partnerName,
              broadcasterImage: widget.partnerAvatar,
              isBusy: isBusy,
              isVideoCall: false, // ← 語音通話
            ),
          ),
        );
      }},
      {'icon': 'assets/message_icon_3.svg', 'label': '視頻', 'onTap': () {
        final isBusy = widget.statusText == 3; // 頁面裡的 3=忙線中
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallRequestPage(
              broadcasterId: (widget.partnerUid ?? -1).toString(),
              broadcasterName: widget.partnerName,
              broadcasterImage: widget.partnerAvatar,
              isBusy: isBusy,
              isVideoCall: true, // ← 視頻通話
            ),
          ),
        );
      }},
      {'icon': 'assets/message_icon_4.svg', 'label': '禮物', 'onTap': () {
        // TODO: 打開送禮面板
      }},
      {'icon': 'assets/message_icon_5.svg', 'label': '圖片', 'onTap': () async {
        await _pickAndSendImage();
      }},
    ];

    return SafeArea(
      top: false,
      child: Container(
        height: 96,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((it) {
            return Expanded(
              child: InkWell(
                onTap: it['onTap'] as VoidCallback,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(it['icon'] as String, width: 56, height: 56),
                    const SizedBox(height: 6),
                    Text(
                      it['label'] as String,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage message) {
    switch (message.contentType) {
      case ChatContentType.text:
        return _buildTextBubble(message.text ?? '');
      case ChatContentType.voice:
        return _buildVoiceBubble(message);
      case ChatContentType.image:
        return _buildImageBubble(message);
      case ChatContentType.call:
        return _buildTextBubble('📞 ${message.text}');
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextBubble(String text) {
    return FutureBuilder<EmojiPack>(
      future: _emojiPackFut,
      builder: (context, snap) {
        final style = const TextStyle(fontSize: 14, color: Colors.black);
        if (snap.connectionState != ConnectionState.done || snap.data == null) {
          // 尚未載入完成時用純文字先顯示
          return Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.symmetric(vertical: 4),
            constraints: const BoxConstraints(maxWidth: 240),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
            child: Text(text, style: style),
          );
        }
        return Container(
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: const BoxConstraints(maxWidth: 240),
          decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
          child: EmojiText(text, pack: snap.data!, style: style, emojiSize: 18),
        );
      },
    );
  }

  Widget _buildVoiceBubble(ChatMessage message) {
    return VoiceBubble(
      key: ValueKey('${message.hashCode}-${message.isPlaying}'),
      message: message,
      onPlay: () => _playAudio(message),
    );
  }

  Widget _buildImageBubble(ChatMessage m) {
    final path = m.imagePath ?? '';
    final img = path.startsWith('http')
        ? Image.network(path, fit: BoxFit.cover)
        : Image.file(File(path), fit: BoxFit.cover);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(maxWidth: 220, maxHeight: 280),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 4/5, // 先給個保守比例，若有寬高可動態算
          child: Stack(
            children: [
              Positioned.fill(child: img),
              if (m.sendState == SendState.sending)
                const Positioned(
                    right: 6, bottom: 6,
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                ),
              if (m.sendState == SendState.failed)
                const Positioned(
                  right: 6, bottom: 6,
                  child: Icon(Icons.error, size: 18, color: Colors.red),
                ),
            ],
          ),
        ),
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
            icon: Icon(
              _isVoiceMode ? Icons.keyboard_alt_outlined : Icons.mic,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _isVoiceMode = !_isVoiceMode;
                _showEmoji = false;
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
                focusNode: _inputFocus,
                maxLines: null,
                inputFormatters: [
                  EmojiBackspaceFixFormatter(EmojiPack.tokenReg),
                ],
                decoration: const InputDecoration(
                  hintText: '請輸入消息…',
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

  Widget _tailStatus(ChatMessage m) {
    switch (m.sendState) {
      case SendState.sending:
      // 傳送中 → 灰色單勾
        return const Icon(
          Icons.check,
          size: 16,
          color: Colors.grey,
        );
      case SendState.sent:
      // 傳送成功 → 藍色單勾
        return const Icon(
          Icons.check,
          size: 16,
          color: Colors.blue,
        );
      case SendState.failed:
      // 傳送失敗 → 紅色錯誤
        return const Icon(
          Icons.error,
          size: 16,
          color: Colors.red,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _toggleEmojiPanel() {
    FocusScope.of(context).unfocus();
    setState(() => _showEmoji = !_showEmoji);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _pickAndSendImage() async {
    // 次數限制
    if (_sendCount >= 10) {
      _showLimitDialog();
      return;
    }

    // 1) 選圖
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90, // 可選：壓縮品質
    );
    if (xfile == null) return;

    final file = File(xfile.path);

    // 2) 拿基本資訊（寬高可選）
    int? w, h;
    try {
      final bytes = await file.readAsBytes();
      final img = await decodeImageFromList(bytes);
      w = img.width; h = img.height;
    } catch (_) {}

    // 3) 準備 id 與對象
    final user = ref.read(userProfileProvider);
    final myUid = int.tryParse(user?.uid ?? '');
    final toUid = widget.partnerUid;
    if (myUid == null || toUid == null) {
      setState(() {
        _messages.add(ChatMessage(
          type: MessageType.self,
          contentType: ChatContentType.image,
          imagePath: file.path, // 本地也先讓使用者看到
          sendState: SendState.failed,
          createAt: cu.nowSec(),
        ));
        _sendCount++;
      });
      _scrollToBottom();
      return;
    }

    final uuid = cu.genUuid(myUid);

    // 4) 樂觀 UI：先顯示本地圖 + sending
    final optimistic = ChatMessage(
      type: MessageType.self,
      contentType: ChatContentType.image,
      imagePath: file.path,      // 先用本地路徑
      uuid: uuid,
      flag: 'chat_person',
      toUid: toUid,
      sendState: SendState.sending,
      createAt: cu.nowSec(),
    );
    setState(() {
      _messages.add(optimistic);
      _sendCount++;
    });
    _scrollToBottom();

    final chatRepo = ref.read(chatRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    try {
      // 5) 上傳 S3（拿相對路徑）
      final rel = await userRepo.uploadToS3(file: file); // e.g. /upload/xx.jpg
      final full = cu.joinCdn(user?.cdnUrl, rel);        // UI 播放用完整 URL

      // 6) 發送圖片訊息（傳相對路徑）
      final ok = await chatRepo.sendImage(
        uuid: uuid,
        toUid: toUid,
        imagePath: rel,
        width: w,
        height: h,
      );

      if (!mounted) return;
      setState(() {
        final i = _messages.indexWhere((m) => m.uuid == uuid);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(
            sendState: ok ? SendState.sent : SendState.failed,
            imagePath: ok ? full : file.path, // 成功→CDN，失敗→留本地
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final i = _messages.indexWhere((m) => m.uuid == uuid);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(
            sendState: SendState.failed,
            imagePath: file.path,
          );
        }
      });
    }
  }

  void _insertAtCursor(String s) {
    final sel = _textController.selection;
    final text = _textController.text;
    if (!sel.isValid) {
      _textController.text = text + s;
      _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
      return;
    }
    final newText = text.replaceRange(sel.start, sel.end, s);
    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(offset: sel.start + s.length);
  }

  ImageProvider _avatar() {
    if (widget.partnerAvatar.startsWith('http')) {
      return NetworkImage(widget.partnerAvatar);
    }
    return NetworkImage('${ref.read(userProfileProvider)?.cdnUrl}${widget.partnerAvatar}');
  }

  String get _presenceLabel {
    final s = widget.statusText;
    if (s == 1 || s == 2) return '當前在線';
    if (s == 3) return '忙線中';
    return '離線';
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

  bool _shouldShowTime(int index) {
    if (index == 0) return true; // 第一則一定顯示
    final prev = _messages[index - 1].createAt ?? 0;
    final curr = _messages[index].createAt ?? 0;
    // 與上一則相差 >= 60 秒才顯示
    return (curr - prev).abs() >= 60;
  }

  String _formatChatTime(int epochSec) {
    if (epochSec <= 0) epochSec = cu.nowSec();    // ✅ 防呆：0 就用現在
    final dt  = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000, isUtc: true).toLocal();
    final now = DateTime.now();

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final yesterday = now.subtract(const Duration(days: 1));

    String two(int v) => v.toString().padLeft(2, '0');
    final hhmm = '${two(dt.hour)}:${two(dt.minute)}';

    if (isSameDay(dt, now)) {
      return hhmm;                         // 當日
    } else if (isSameDay(dt, yesterday)) {
      return '昨日 $hhmm';                  // 昨日
    } else {
      return '${dt.year}/${two(dt.month)}/${two(dt.day)} $hhmm';
    }
  }

  Widget _timeLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEDEDED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      ),
    );
  }

}

