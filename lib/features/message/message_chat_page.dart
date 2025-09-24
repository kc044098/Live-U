import 'dart:async';
import 'dart:collection';
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
import '../../data/models/gift_item.dart';
import '../../data/models/user_model.dart';
import '../call/call_request_page.dart';
import '../live/data_model/gift_effect_player.dart';
import '../live/gift_providers.dart';
import '../mine/edit_mine_page.dart';
import '../mine/user_repository_provider.dart';
import '../profile/profile_controller.dart';
import '../profile/view_profile_page.dart';
import 'chat_repository.dart';
import 'chat_utils.dart' as cu;
import 'chat_message.dart';
import 'chat_providers.dart';
import 'chat_ws_service.dart';
import 'emoji/emoji_editing_controller.dart';
import 'emoji/emoji_input_formatter.dart';
import 'emoji/emoji_pack.dart';
import 'emoji/emoji_picker_panel.dart';
import 'emoji/emoji_text.dart';
import 'gift/gift_bottom_sheet.dart';
import 'gift_bubble.dart';

CalleeState _mapStatusToCalleeState(int s) {
  if (s == 1 || s == 2) return CalleeState.online;
  if (s == 3 || s == 4 || s == 5) return CalleeState.busy;
  return CalleeState.offline;
}

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

class _MessageChatPageState extends ConsumerState<MessageChatPage> with SingleTickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  late TextEditingController _textController;
  final ScrollController _scrollController = ScrollController();
  final RefreshController _refreshCtrl = RefreshController(initialRefresh: false);

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<VoidCallback> _wsUnsubs = [];

  late Future<EmojiPack> _emojiPackFut;

  int? _asInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v');
  bool _showEmoji = false;

  bool _isVoiceMode = false;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;

  bool _isLoadingMore = false;
  bool _loading = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;

  late VoidCallback _wsUnsubRoomChat;
  late VoidCallback _wsUntapRaw;

  late final FocusNode _inputFocus;

  int _lastReadPostMs = 0;

  late final GiftEffectPlayer _giftFx;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _giftFx = GiftEffectPlayer(vsync: this);

    attachCursorGuardForPlatform(_textController, EmojiPack.tokenReg);

    // 監聽輸入焦點
    _inputFocus = FocusNode();
    _inputFocus.addListener(() {
      if (_inputFocus.hasFocus && _showEmoji) {
        setState(() {
          _showEmoji = false;
        });
        _scrollToBottom();
      }
    });
    _emojiPackFut = EmojiPack.loadFromFolder('assets/emojis/basic/').then((pack) {
      final old = _textController;
      _textController = EmojiEditingController(pack: pack, emojiSize: 18, text: old.text)
        ..selection = old.selection;
      old.dispose();
      attachCursorGuardForPlatform(_textController, EmojiPack.tokenReg);
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

      // 讀目前禮物列表（若還在載入就給空陣列）
      final gifts = ref.read(giftListProvider).maybeWhen(
        data: (v) => v,
        orElse: () => const <GiftItemModel>[],
      );

      final msgs = list
          .map((m) => _fromApiMsg(
        Map<String, dynamic>.from(m),
        myUid: myUid,
        cdnBase: cdnBase,
        gifts: gifts,
      ))
          .toList()
        ..sort((a, b) => (a.createAt ?? 0).compareTo(b.createAt ?? 0));

      setState(() {
        _messages
          ..clear()
          ..addAll(msgs);
        final latest = _messages.isNotEmpty ? _messages.last : null;
        if (latest != null && latest.type == MessageType.other) {
          _markThreadReadOptimistic();
        }
        _loading = false;
        _hasMore = list.isNotEmpty;
        _page = 1;
      });
      _refreshCtrl.resetNoData();
      _refreshCtrl.loadComplete();
      _scrollToBottom();
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
    try { _giftFx.dispose(); } catch (_) {}
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
      // 先上傳 S3（需要路徑才可發送）
      final rel = await userRepo.uploadToS3(file: File(path));
      final full = cu.joinCdn(user?.cdnUrl, rel);

      final SendResult res = await chatRepo.sendVoice(
        uuid: uuid,
        toUid: toUid,
        voicePath: rel,
        durationSec: _recordDuration.toString(),
      );

      if (!mounted) return;

      // 若超上限 → 撤回樂觀訊息 + 彈窗
      if (_handleQuotaAndMaybeRollback(res, uuid: uuid)) return;

      setState(() {
        final i = _messages.indexWhere((m) => m.uuid == uuid);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(
            sendState: res.ok ? SendState.sent : SendState.failed,
            audioPath: res.ok ? full : path, // 成功→CDN，失敗→留本地
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
            audioPath: path,
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

  bool _shouldShowBottomActions(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return !_showEmoji && !keyboardOpen;
  }

  void _sendMessage() async {
    _inputFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(userProfileProvider);
    final myUid = int.tryParse(user?.uid ?? '');
    final toUid = widget.partnerUid;

    // 取不到 id：照舊（顯示失敗的本地訊息），這段可以保留
    if (myUid == null || toUid == null) {
      setState(() {
        _messages.add(ChatMessage(
          type: MessageType.self,
          contentType: ChatContentType.text,
          text: text,
          sendState: SendState.failed,
        ));
        _showEmoji = false;
      });
      _textController.clear();
      _scrollToBottom();
      return;
    }

    final uuid = cu.genUuid(myUid);

    // 樂觀加入
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
      _showEmoji = false;
    });
    _textController.clear();
    _scrollToBottom();

    // ★ 這裡開始使用 SendResult，而不是 bool
    final repo = ref.read(chatRepositoryProvider);
    final SendResult res = await repo.sendText(uuid: uuid, toUid: toUid, text: text);

    if (!mounted) return;

    // 命中「超出上限」：撤回訊息 + 彈窗，直接 return
    if (_handleQuotaAndMaybeRollback(res, uuid: uuid)) return;

    // 其它錯誤 → 樂觀訊息標記失敗；成功 → 樂觀訊息標記 sent
    setState(() {
      final i = _messages.indexWhere((m) => m.uuid == uuid);
      if (i >= 0) {
        _messages[i] = _messages[i].copyWith(
          sendState: res.ok ? SendState.sent : SendState.failed,
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
                                broadcasterId: (widget.partnerUid ?? -1).toString(),
                                broadcasterName: widget.partnerName,
                                broadcasterImage: widget.partnerAvatar,
                                isVideoCall: true, // ← 語音通話
                                calleeState: _mapStatusToCalleeState(widget.statusText),
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

  int _parseEpochSec(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  void _markThreadReadOptimistic() {
    final id = widget.partnerUid;
    if (id == null) return;

    // 極簡節流：800ms 內只送一次，避免 WS 積木瞬間多次觸發
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastReadPostMs < 800) return;
    _lastReadPostMs = now;

    // 樂觀呼叫即可，不 await
    unawaited(ref.read(chatRepositoryProvider).messageRead(id: id));
  }

  void _removeOptimisticByUuid(String uuid) {
    if (uuid.isEmpty) return;
    setState(() {
      _messages.removeWhere((m) => m.uuid == uuid);
    });
  }

  /// 統一處理送訊息後的結果：命中 101 就彈窗並撤回
  bool _handleQuotaAndMaybeRollback(SendResult res, {String? uuid}) {
    if (res.code == 101) {
      if (uuid != null) _removeOptimisticByUuid(uuid);
      _showLimitDialog();
      return true; // 表示已處理（命中上限）
    }
    return false;
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

            // ★ 對方來的新訊息 → 樂觀標記已讀
            if (msg.type == MessageType.other) {
              _markThreadReadOptimistic();
            }

            _tryPlayGiftFromMessage(msg);

            final atBottom = !_scrollController.hasClients
                || _scrollController.position.pixels <= 40;
            if (atBottom) _scrollToBottom();
          });
        },
      );
      ref.listen<AsyncValue<ReadReceipt>>(
        roomReadProvider(partnerUid),
            (prev, next) {
          next.whenData((rcpt) {
            if (!mounted) return;

            setState(() {
              for (var i = 0; i < _messages.length; i++) {
                final m = _messages[i];

                // 只標記「我發出的」訊息
                if (m.type != MessageType.self) continue;

                // 若後端帶了 createAt，就把「當時（含）之前的」都設為已讀；
                // 若沒帶（=0），就全設為已讀（符合你「都設為雙勾」的需求）
                final okToMark = (rcpt.createAt == 0)
                    || ((m.createAt ?? 0) <= rcpt.createAt);

                if (okToMark) {
                  _messages[i] = m.copyWith(readStatus: 2); // 2=已讀 → 雙勾
                }
              }
            });
          });
        },
      );
    }

    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            // 原本的整個 Column（不包含你那個 Positioned）
            Column(
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _shouldShowBottomActions(context)
                      ? _buildBottomActions()
                      : const SizedBox.shrink(),
                ),
              ],
            ),

          ],
        ),
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
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _openPartnerProfile,
            child: Stack(
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
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _openPartnerProfile,
            child: CircleAvatar(
              radius: 16,
              backgroundImage: _avatar(),
            ),
          ),

        if (!isSelf) const SizedBox(width: 8),

        // 訊息氣泡
        _buildBubble(message),

        if (isSelf) const SizedBox(width: 6),
        if (isSelf) _tailStatus(message),
        if (isSelf) const SizedBox(width: 8),

        if (isSelf)
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _openMyProfile,
            child: CircleAvatar(
              radius: 16,
              backgroundImage: user?.avatarImage ?? const AssetImage('assets/my_icon_defult.jpeg'),
            ),
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallRequestPage(
              broadcasterId: (widget.partnerUid ?? -1).toString(),
              broadcasterName: widget.partnerName,
              broadcasterImage: widget.partnerAvatar,
              isVideoCall: false,
              calleeState: _mapStatusToCalleeState(widget.statusText),
            ),
          ),
        );
      }},
      {'icon': 'assets/message_icon_3.svg', 'label': '視頻', 'onTap': () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CallRequestPage(
              broadcasterId: (widget.partnerUid ?? -1).toString(),
              broadcasterName: widget.partnerName,
              broadcasterImage: widget.partnerAvatar,
              isVideoCall: true, // ← 視頻通話
              calleeState: _mapStatusToCalleeState(widget.statusText),
            ),
          ),
        );
      }},
      {'icon': 'assets/message_icon_4.svg', 'label': '禮物', 'onTap': _openGiftSheet},
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
      case ChatContentType.gift:
        final d = message.data ?? const {};
        final title = (d['gift_title'] ?? message.text ?? '').toString();
        final icon  = (d['gift_icon'] ?? '').toString();
        final cnt   = (d['gift_count'] ?? 1);
        final count = (cnt is num) ? cnt.toInt() : int.tryParse('$cnt') ?? 1;
        return GiftBubble(
          title: title,
          count: count,
          iconUrl: icon,
          isSelf: message.type == MessageType.self,
        );
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



  Map<String, dynamic>? _decodeJsonMap(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final v = jsonDecode(s);
      if (v is Map) {
        return v.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic>? _parseGiftPayloadFromChatText(String? chatText) {
    final inner = _decodeJsonMap(chatText);
    final type = (inner?['type'] ?? inner?['t'])?.toString().toLowerCase();
    if (type == 'gift') return inner;
    return null;
  }

  String _fullUrl(String base, String p) {
    if (p.isEmpty) return p;
    if (p.startsWith('http')) return p;
    if (base.isEmpty) return p;
    return p.startsWith('/') ? '$base$p' : '$base/$p';
  }

  ChatMessage _fromApiMsg(
      Map<String, dynamic> m, {
        required int myUid,
        required String cdnBase,
        List<GiftItemModel> gifts = const [],
      }) {
    final senderUid  = (m['uid'] as num?)?.toInt() ?? -1;
    final readStatus = _asInt(m['status']);
    final rawContent = (m['content'] ?? '').toString();
    final createAt   = _parseEpochSec(m['create_at']);

    Map<String, dynamic>? c;
    try {
      final tmp = jsonDecode(rawContent);
      if (tmp is Map) c = tmp.map((k, v) => MapEntry('$k', v));
    } catch (_) {}

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
        sendState: senderUid == myUid ? SendState.sent : null, // ★
        readStatus: readStatus, // ★
      );
    }

    // 語音
    if ((voicePathRel ?? '').isNotEmpty) {
      final full = cu.joinCdn(cdnBase, voicePathRel!);
      return ChatMessage(
        type: senderUid == myUid ? MessageType.self : MessageType.other,
        contentType: ChatContentType.voice,
        audioPath: full,
        duration: duration,
        createAt: createAt,
        sendState: senderUid == myUid ? SendState.sent : null, // ★
        readStatus: readStatus, // ★
      );
    }

    // ★ 禮物：chat_text 內藏 JSON
    final gift = _parseGiftPayloadFromChatText(chatText);
    if (gift != null) {
      final id    = _asInt(gift['gift_id'] ?? gift['id']) ?? -1;
      String title = (gift['gift_title'] ?? gift['title'] ?? '').toString();
      String iconRel = (gift['gift_icon'] ?? gift['icon'] ?? '').toString();
      final gold  = _asInt(gift['gift_gold'] ?? gift['gold']) ?? 0;
      final count = _asInt(gift['gift_count']) ?? 1;

      // 若歷史訊息缺 icon/title，嘗試用目前禮物表補齊
      if ((iconRel.isEmpty || title.isEmpty) && id >= 0) {
        final match = gifts.where((g) => g.id == id).toList();
        if (match.isNotEmpty) {
          iconRel = iconRel.isEmpty ? match.first.icon : iconRel;
          title   = title.isEmpty   ? match.first.title : title;
        }
      }

      final iconFull = cu.joinCdn(cdnBase, iconRel); // 顯示用完整 URL
      return ChatMessage(
        type: senderUid == myUid ? MessageType.self : MessageType.other,
        contentType: ChatContentType.gift,
        text: title,
        data: {
          'gift_id'   : id,
          'gift_title': title,
          'gift_icon' : iconFull,
          'gift_gold' : gold,
          'gift_count': count,
        },
        createAt: createAt,
        sendState: senderUid == myUid ? SendState.sent : null, // ★
        readStatus: readStatus, // ★
      );
    }

    // 普通文字
    return ChatMessage(
      type: senderUid == myUid ? MessageType.self : MessageType.other,
      contentType: ChatContentType.text,
      text: (chatText != null && chatText.isNotEmpty) ? chatText : rawContent,
      createAt: createAt,
      sendState: senderUid == myUid ? SendState.sent : null, // ★
      readStatus: readStatus, // ★
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
                  platformEmojiBackspaceFormatter(EmojiPack.tokenReg),
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
                gradient: const LinearGradient(colors: [Color(0xFFFFB56B), Color(0xFFDF65F8)]),
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
    // 只展示自己的訊息
    if (m.type != MessageType.self) return const SizedBox.shrink();

    // 送出中 / 失敗優先判斷
    if (m.sendState == SendState.sending) {
      return const Icon(Icons.check, size: 16, color: Colors.grey);
    }
    if (m.sendState == SendState.failed) {
      return const Icon(Icons.error, size: 16, color: Colors.red);
    }

    // 已送達（歷史訊息沒有 sendState 時也走這裡）
    // readStatus: 1=未讀 → 單勾；2=已讀 → 雙勾
    if (m.readStatus == 2) {
      return const Icon(Icons.done_all, size: 16, color: Colors.blue); // ★ 已讀
    } else {
      return const Icon(Icons.check, size: 16, color: Colors.blue);    // ★ 未讀/未知
    }
  }


  void _toggleEmojiPanel() {
    FocusScope.of(context).unfocus();
    setState(() => _showEmoji = !_showEmoji);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _pickAndSendImage() async {

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
    });
    _scrollToBottom();

    final chatRepo = ref.read(chatRepositoryProvider);
    final userRepo = ref.read(userRepositoryProvider);

    try {
      // 5) 上傳 S3（拿相對路徑）
      final rel = await userRepo.uploadToS3(file: file); // e.g. /upload/xx.jpg
      final full = cu.joinCdn(user?.cdnUrl, rel);        // UI 播放用完整 URL

      // 6) 發送圖片訊息（傳相對路徑）
      final SendResult res = await chatRepo.sendImage(
        uuid: uuid,
        toUid: toUid,
        imagePath: rel,
        width: w,
        height: h,
      );

      if (!mounted) return;

      // 若超上限 → 撤回樂觀訊息 + 彈窗
      if (_handleQuotaAndMaybeRollback(res, uuid: uuid)) return;

      setState(() {
        final i = _messages.indexWhere((m) => m.uuid == uuid);
        if (i >= 0) {
          _messages[i] = _messages[i].copyWith(
            sendState: res.ok ? SendState.sent : SendState.failed,
            imagePath: res.ok ? full : file.path,
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

  // 從 ChatMessage 嘗試取得 SVGA url（ws/歷史皆可）
  void _tryPlayGiftFromMessage(ChatMessage msg) {
    if (msg.contentType != ChatContentType.gift) return;

    // 1) 直接拿 data.gift_url（若後端有帶）
    String url = (msg.data?['gift_url'] ?? '').toString();

    // 2) 沒帶就用 id 對照本地禮物清單
    if (url.isEmpty) {
      final id = (msg.data?['gift_id'] ?? msg.data?['id']);
      final giftId = (id is num) ? id.toInt() : int.tryParse('$id');
      if (giftId != null) {
        final gifts = ref.read(giftListProvider).maybeWhen(
          data: (v) => v,
          orElse: () => const <GiftItemModel>[],
        );
        for (final g in gifts) {
          if (g.id == giftId && g.url.isNotEmpty) {
            url = cu.joinCdn(ref.read(userProfileProvider)?.cdnUrl, g.url);
            break;
          }
        }
      }
    }

    if (url.isNotEmpty) _enqueueGift(url);
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

  void _openGiftSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return GiftBottomSheet(
          onSelected: (gift) async {
            final user = ref.read(userProfileProvider);
            final myUid = int.tryParse(user?.uid ?? '0')!;
            final toUid = widget.partnerUid ?? 0;
            final uuid = cu.genUuid(myUid);

            // ★ 先播本地特效（相對路徑→完整 URL）
            final effectUrl = cu.joinCdn(user?.cdnUrl, gift.url);
            _enqueueGift(effectUrl);

            // payload（後端扣款/留存）
            final payload = jsonEncode({
              'type': 'gift',
              'gift_id': gift.id,
              'gift_title': gift.title,
              'gift_gold': gift.gold,
              'gift_icon': gift.icon, // 相對路徑
              'gift_count': 1,
              // 可選：也把 gift_url 帶給對端，方便它端解析
              'gift_url': gift.url,
            });

            // 樂觀 UI（略，同你原有）
            final iconFull = cu.joinCdn(user?.cdnUrl, gift.icon);
            final optimistic = ChatMessage(
              type: MessageType.self,
              contentType: ChatContentType.gift,
              text: gift.title,
              uuid: uuid,
              flag: 'chat_gift',
              toUid: toUid,
              data: {
                'gift_id': gift.id,
                'gift_title': gift.title,
                'gift_icon': iconFull,
                'gift_gold': gift.gold,
                'gift_count': 1,
                'gift_url': gift.url,
              },
              sendState: SendState.sending,
              createAt: cu.nowSec(),
            );
            setState(() => _messages.add(optimistic));
            _scrollToBottom();

            final sendResult = await ref.read(chatRepositoryProvider).sendText(
              uuid: uuid,
              toUid: toUid,
              text: payload,
              flag: 'chat_gift',
            );

            if (!mounted) return sendResult.ok;
            final i = _messages.indexWhere((m) => m.uuid == uuid);
            if (i >= 0) {
              setState(() {
                _messages[i] = _messages[i].copyWith(
                  sendState: sendResult.ok ? SendState.sent : SendState.failed,
                );
              });
            }
            return sendResult.ok;
          },
        );
      },
    );
  }

  void _enqueueGift(String url) {
    if (url.isEmpty) return;
    _giftFx.enqueue(context, url);
  }

  Future<bool> _handleBack() async {
    if (_showEmoji) {
      setState(() => _showEmoji = false);
      FocusScope.of(context).unfocus();
      _scrollToBottom();
      return false; // 攔截返回：只關面板
    }
    return true; // 沒有面板 → 允許返回
  }

  ImageProvider _avatar() {
    if (widget.partnerAvatar.startsWith('http')) {
      return NetworkImage(widget.partnerAvatar);
    }
    return NetworkImage('${ref.read(userProfileProvider)?.cdnUrl}${widget.partnerAvatar}');
  }

  String get _presenceLabel {
    final s = widget.statusText;
    if (s == 0) return '離線';
    if (s == 1 || s == 2) return '當前在線';
    if (s == 3 || s == 4 || s == 5) return '忙線中';
    return '離線';
  }

  void _openPartnerProfile() {
    final uid = widget.partnerUid;
    if (uid == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ViewProfilePage(userId: uid)),
    );
  }

  void _openMyProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditMinePage()),
    );
  }

  Color _getStatusColor(int index) {
    switch (index) {
      case 0:
        return Colors.grey; // 離線
      case 1:
      case 2:
        return Colors.green; // 上線
      case 3:
      case 4:
      case 5:
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

