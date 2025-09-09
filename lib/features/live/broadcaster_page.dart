import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/ws/ws_provider.dart';
import '../../globals.dart';
import '../../routes/app_routes.dart';
import '../call/call_repository.dart';
import '../call/rtc_engine_manager.dart';
import '../message/chat_message.dart';
import '../message/chat_providers.dart';
import '../message/chat_utils.dart' as cu;
import '../profile/profile_controller.dart';
import 'call_session_provider.dart';
import 'data_model/call_overlay.dart';
import 'data_model/call_timer.dart';
import 'data_model/live_chat_input_bar.dart';
import 'data_model/live_chat_panel.dart';
import 'mini_call_view.dart';

class BroadcasterPage extends ConsumerStatefulWidget {
  const BroadcasterPage({super.key});

  @override
  ConsumerState<BroadcasterPage> createState() => _BroadcasterPageState();
}

class _BroadcasterPageState extends ConsumerState<BroadcasterPage>
    with WidgetsBindingObserver {
  String roomId = '';
  String title = '';
  String desc = '';
  String? rtcToken;
  bool isCallMode = false;
  bool asBroadcaster = true;
  String peerAvatar = '';

  final List<int> _remoteUids = [];
  final List<VoidCallback> _wsUnsubs = [];

  bool _argsReady = false;
  bool _joined = false;
  bool _closing = false;

  Timer? _joinTimeout; // 10 秒入房守門

  late final RtcEngineManager _rtc; // ✅ 使用全域 manager
  late final VoidCallback _joinedListener;
  late final VoidCallback _remoteListener;

  // 文字聊天室
  late final TextEditingController _liveInputCtrl = TextEditingController();
  late final FocusNode _liveInputFocus = FocusNode();
  final ScrollController _liveScroll = ScrollController();

  VoidCallback? _wsUnsubLiveChat;

  final GlobalKey _localPreviewKey = GlobalKey();

  Map<String, dynamic> _dataOf(Map p) =>
      (p['data'] is Map) ? Map<String, dynamic>.from(p['data']) : const {};

  String _ch(Map p) => _dataOf(p)['channel_id']?.toString() ?? '';

  int? _asInt(dynamic v) =>
      (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '');

  int? _statusOf(Map p) => _asInt(_dataOf(p)['status']);

  bool _isThisChannel(Map p) => _ch(p) == roomId;

  // ---------------------------------------------------------------

  CallType _callType = CallType.video; // 預設先給 video
  bool get _isVoice => _callType == CallType.voice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _rtc = RtcEngineManager(); // 已在 app 啟動 init 過
    // joined 後啟動共享計時
    _joinedListener = () async {
      final j = _rtc.joined.value;
      if (j && mounted) {
        _cancelJoinTimeout();
        ref.read(callTimerProvider).start();      // ← 啟動共享 timer
        setState(() => _joined = true);
        await _ensureAwake();
      }
    };

    _remoteListener = () {
      if (!mounted) return;
      setState(() {
        _remoteUids
          ..clear()
          ..addAll(_rtc.remoteUids.value);
      });
    };
    // 綁定全域通知
    _rtc.joined.addListener(_joinedListener);
    _rtc.remoteUids.addListener(_remoteListener);

    if (CallOverlay.isShowing) CallOverlay.hide();

  }

  Future<void> _endBecauseRemoteLeft() async {
    if (_closing) return;
    _closing = true;

    // 先停本地狀態與計時
    _cancelJoinTimeout();
    ref.read(callTimerProvider).reset();
    ref.read(callSessionProvider(roomId).notifier).clearAll();
    if (_joined) {
      Fluttertoast.showToast(msg: '對方已離開聊天室');
    }

    // ✅ 交給全域 manager 做安全離房（會處理 stopPreview/清理狀態）
    try {
      await _rtc.safeLeave();
    } catch (e) {
      debugPrint('[RTC] safeLeave error: $e');
    }

    unawaited(WakelockPlus.disable());

    await _closeMiniIfAny();
    _goHome();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsReady) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    debugPrint('🎯[RTC] route args=$args');

    if (args is Map<String, dynamic>) {
      roomId = (args['roomId'] ?? '').toString();
      title = (args['title'] ?? '').toString();
      desc = (args['desc'] ?? '').toString();
      rtcToken = args['token'] as String?;
      isCallMode = args['isCallMode'] == true;
      asBroadcaster = args['asBroadcaster'] != false;
      peerAvatar   = (args['peerAvatar'] ?? '').toString();

      _applyCallFlagFromArgs(args);

      final s = ref.read(callSessionProvider(roomId));
      _liveInputCtrl.text = s.draft;
      _liveInputCtrl.removeListener(_onDraftChanged);
      _liveInputCtrl.addListener(_onDraftChanged);

      _argsReady = true;
      _enterRoom();
      _listenCallSignals();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onDraftChanged() {
    if (roomId.isEmpty) return;
    ref.read(callSessionProvider(roomId).notifier).setDraft(_liveInputCtrl.text);
  }

  Future<void> _enterRoom() async {
    // 權限
    final perms = await [Permission.microphone, Permission.camera].request();
    final mic = perms[Permission.microphone];
    final cam = perms[Permission.camera];
    final needCamera = !_isVoice;
    if (mic != PermissionStatus.granted ||
        (needCamera && cam != PermissionStatus.granted)) {
      Fluttertoast.showToast(msg: '請先授權麥克風${needCamera ? '與相機' : ''}');
      if (mounted) Navigator.of(context).pop();
      return;
    }

    await WakelockPlus.enable();

    // 啟動入房逾時（建議 15~20s，先保留你原 10s）
    _armJoinTimeout();

    final mUser = ref.read(userProfileProvider);
    final profile =
        ChannelProfileType.channelProfileCommunication; // 1v1 通話建議用這個
    final role = ClientRoleType.clientRoleBroadcaster;

    debugPrint(
        '➡️[RTC] join channel=$roomId uid=${mUser!.uid} tokenLen=${rtcToken?.length} voice=$_isVoice');

    await _rtc.join(
      channelId: roomId,
      uid: int.parse(mUser.uid),
      token: rtcToken ?? '',
      profile: profile,
      role: role,
      isVoice: _isVoice,
    );
  }

  void _goHome() {
    final ctx = rootNavigatorKey.currentContext ?? context;
    Navigator.of(ctx, rootNavigator: true)
        .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  // === 只用新事件與新欄位 ===
  void _listenCallSignals() {
    final ws = ref.read(wsProvider);

    // 對方拒絕/結束：call.accept(status=2)
    _wsUnsubs.add(ws.on('call.accept', (p) {
      if (!_isThisChannel(p)) return;
      final st = _statusOf(p);
      if (st == 2) _endBecauseRemoteLeft();
    }));

    // 有些情況後端仍用 invite 通知結束（status=2/3/4）
    _wsUnsubs.add(ws.on('call.invite', (p) {
      if (!_isThisChannel(p)) return;
      final st = _statusOf(p);
      if (st == 2 || st == 3 || st == 4) _endBecauseRemoteLeft();
    }));

    // 若後端在通話中還會另外丟 end/timeout，就照 channel_id 收
    _wsUnsubs.add(ws.on('call.end', (p) {
      if (_isThisChannel(p)) _endBecauseRemoteLeft();
    }));
    _wsUnsubs.add(ws.on('call.timeout', (p) {
      if (_isThisChannel(p)) _endBecauseRemoteLeft();
    }));
    _wsUnsubs.add(ws.on('call.cancel', (p) {
      if (_isThisChannel(p)) _endBecauseRemoteLeft();
    }));

    _wsUnsubLiveChat = ws.on('live_chat', _onWsLiveChat);
    _wsUnsubs.add(_wsUnsubLiveChat!);
  }

  Widget _buildRemoteView() {
    if (_isVoice) return const ColoredBox(color: Colors.white);
    if (!_rtc.isInited || _rtc.engine == null || _remoteUids.isEmpty) {
      return const ColoredBox(color: Colors.black);
    }
    final remoteUid = _remoteUids.first;
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _rtc.engine,
        // ✅ 全域引擎
        canvas: VideoCanvas(uid: remoteUid),
        connection: RtcConnection(channelId: roomId),
        useFlutterTexture: true,
        useAndroidSurfaceView: false,
      ),
    );
  }

  Widget _buildLocalViewMirrored() {
    if (_isVoice || !_rtc.isInited) return const SizedBox.shrink();
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _rtc.engine, // ✅ 全域引擎
        canvas: const VideoCanvas(
          uid: 0,
          mirrorMode: VideoMirrorModeType.videoMirrorModeEnabled,
        ),
        useFlutterTexture: true,
        useAndroidSurfaceView: false,
      ),
    );
  }

  void _cancelJoinTimeout() {
    _joinTimeout?.cancel();
    _joinTimeout = null;
  }

  void _armJoinTimeout() {
    _cancelJoinTimeout();
    _joinTimeout = Timer(const Duration(seconds: 10), () async {
      if (!mounted || _joined || _closing) return;
      Fluttertoast.showToast(msg: '通話連線接通失敗');
      _closing = true;

      await _rtc.safeLeave(); // ✅ 不要 release，全交給 manager

      await _closeMiniIfAny();
      _goHome();
    });
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;


    // 後端規定：離開也用 respondCall(flag=2)
    final repo = ref.read(callRepositoryProvider);
    ref.read(callSessionProvider(roomId).notifier).clearAll();
    unawaited(
      repo
          .respondCall(
            channelName: roomId,
            callId: null,
            accept: false,
          )
          .timeout(const Duration(seconds: 2),
              onTimeout: () => <String, dynamic>{})
          .then<void>((_) {}, onError: (e) {
        debugPrint('[hangup] notify fail: $e');
      }),
    );

    await _rtc.safeLeave();

    unawaited(WakelockPlus.disable());
    ref.read(callTimerProvider).reset();

    await _closeMiniIfAny();
    _goHome();
  }

  Future<void> _ensureAwake() async {
    try {
      final on = await WakelockPlus.enabled;
      if (!on) {
        await WakelockPlus.enable();
        debugPrint('[wakelock] re-enabled');
      }
    } catch (e) {
      debugPrint('[wakelock] enable err: $e');
    }
  }

  Future<void> _closeMiniIfAny() async {
    if (CallOverlay.isShowing) {
      CallOverlay.hide();
      // 等一幀避免 overlay 殘影疊在新頁上
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rtc.joined.removeListener(_joinedListener);
    _rtc.remoteUids.removeListener(_remoteListener);


    _liveInputCtrl.dispose();
    _liveInputFocus.dispose();
    _liveScroll.dispose();
    try { _wsUnsubLiveChat?.call(); } catch (_) {}

    _cancelJoinTimeout();
    for (final u in _wsUnsubs) {
      try {
        u();
      } catch (_) {}
    }
    _wsUnsubs.clear();

    WakelockPlus.disable();

    super.dispose();
  }

  void _goMini() {
    final rootCtx = Navigator.of(context, rootNavigator: true).context;

    final navArgs = {
      'roomId'       : roomId,
      'token'        : rtcToken,
      'title'        : title,
      'desc'         : desc,
      'isCallMode'   : true,
      'asBroadcaster': asBroadcaster,
      'peerAvatar'   : peerAvatar,
      'callFlag'     : _isVoice ? 2 : 1,
    };

    CallOverlay.show(
      navigatorKey: rootNavigatorKey,
      child: MiniCallView(
        rootContext: rootNavigatorKey.currentContext!,
        roomId: roomId,
        isVoice: _isVoice,
        remoteUid: _remoteUids.isNotEmpty ? _remoteUids.first : null,
        onExpand: () {
          CallOverlay.hide();
          Navigator.of(rootCtx).pushNamed(AppRoutes.broadcaster, arguments: navArgs);
        },
      ),
    );

    // 把首頁頂上來，通話頁保留在棧中，RTC 仍由全域 manager 維持
    Navigator.of(rootCtx).pushNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final Color fg = _isVoice ? Colors.black : Colors.white;
    final Color chipBg = _isVoice
        ? Colors.black.withOpacity(0.05)
        : Colors.black.withOpacity(0.35);
    final Color chipFg = _isVoice ? Colors.black87 : Colors.white;

    final avatarRadius = 60.0;               // 可調
    final avatarDia    = avatarRadius * 2;
    final elapsedText = ref.watch(callTimerProvider.select((t) => t.text));
    final mUser = ref.read(userProfileProvider);
    final ImageProvider avatarProvider = (peerAvatar.isNotEmpty)
        ? NetworkImage(peerAvatar) as ImageProvider
        : const AssetImage('assets/my_icon_defult.jpeg');

    if (!_argsReady || _rtc.engine == null || !_joined) {
      return Scaffold(
        backgroundColor: _isVoice ? Colors.white : Colors.black,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (Platform.isAndroid) {
          _goMini();
          return false; // ← 不要離開頁面
        }
        return true; // iOS 正常返回
      },
      child: Scaffold(
        backgroundColor: _isVoice ? Colors.white : Colors.black,
        body: Stack(
          children: [
            // 遠端畫面全屏
            Positioned.fill(child: _buildRemoteView()),

            // 左上：縮小（改成 App 內小窗）
            Positioned(
              top: top + 6,
              left: 12,
              child: IconButton(
                icon: Image.asset('assets/zoom.png', width: 20, height: 20),
                onPressed: _goMini, // <= 這行
                tooltip: '縮小畫面',
                splashRadius: 22,
              ),
            ),

            // 上方置中：對方名字
            if (!_isVoice)
            Positioned(
              top: top + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  title.isEmpty ? '' : title,
                  style: TextStyle(
                      color: fg, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // 名字下方 計時膠囊
            Positioned(
              top: top + 56,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _joined ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.only(top: 4),
                    width: 120,
                    height: 26,
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      elapsedText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: chipFg,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 右上：白色 X 關閉
            Positioned(
              top: top + 6,
              right: 12,
              child: IconButton(
                icon: Icon(Icons.close, color: fg, size: 22),
                onPressed: _close,
                tooltip: '關閉',
                splashRadius: 22,
              ),
            ),

            // 語音模式：頂部 30 顯示大頭照 + 名稱
            if (_isVoice)
              Positioned(
                top: top + 180,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: avatarRadius, backgroundImage: avatarProvider),
                    const SizedBox(height: 16),
                    Text(
                      title.isEmpty ? '' : title,
                      style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // 本地預覽：右側偏上（加陰影）
            if (!_isVoice)
              Positioned(
                right: 12,
                top: top + 120,
                width: 120,
                height: 160,
                child: Container(
                  key: _localPreviewKey,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildLocalViewMirrored(),
                  ),
                ),
              ),

            // ====== 透明聊天紀錄框（左下，顯示最近訊息）======
            Positioned(
              left: 12,
              bottom: 70, // 留給輸入框高度
              child: LiveChatPanel(
                messages: ref.watch(callSessionProvider(roomId).select((s) => s.messages)),
                controller: _liveScroll,
                myName: mUser?.displayName ?? '用戶 ${_remoteUids.first}',
                peerName: title,
              ),
            ),

            // ====== 左下輸入框 ======
            Positioned(
              left: 12,
              bottom: 20,
              right: MediaQuery.of(context).size.width * 0.55, // 右側保留空間（避免蓋住本地預覽）
              child: LiveChatInputBar(
                controller: _liveInputCtrl,
                focusNode: _liveInputFocus,
                onSend: _sendLiveText,
                onTapField: () {}, // 需要時可關閉別的面板
              ),
            ),


          ],
        ),
      ),
    );
  }

  void _onWsLiveChat(Map<String, dynamic> payload) {
    try {
      // --- 取出內層 data ---
      final data = (payload['Data'] is Map)
          ? Map<String, dynamic>.from(payload['Data'])
          : (payload['data'] is Map)
          ? Map<String, dynamic>.from(payload['data'])
          : const <String, dynamic>{};

      // --- 可選：保險型 type 檢查（接受 flag 或 type），也可以整段移除 ---
      final tRaw = payload['type'] ?? payload['Type'] ?? payload['flag'] ?? payload['Flag'];
      final tVal = (tRaw is num) ? tRaw.toInt() : int.tryParse('$tRaw');
      if (tVal != null && tVal != 3) return; // 不是 live_chat 就跳出（多一道保險）

      // --- 內容：可能是純字串或 JSON {"chat_text": "..."} ---
      final content = (data['Content'] ?? data['content'] ?? '').toString();
      if (content.isEmpty) return;

      String chatText = content;
      try {
        final obj = jsonDecode(content);
        if (obj is Map && obj['chat_text'] != null) {
          chatText = obj['chat_text'].toString();
        }
      } catch (_) { /* 不是 JSON 就用原字串 */ }

      // --- 參與人比對（因封包沒有 channel_id，用 uid / to_uid 判斷是否這一房的 1v1） ---
      int _toInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? -1;

      final fromUid = _toInt(data['Uid'] ?? payload['Uid'] ?? data['uid'] ?? payload['uid']);
      final toUid   = _toInt(data['ToUid'] ?? payload['ToUid'] ?? data['to_uid'] ?? payload['toUid']);

      final me   = ref.read(userProfileProvider);
      final myUid = int.tryParse(me?.uid ?? '') ?? -1;
      final remote = _remoteUids.isNotEmpty ? _remoteUids.first : null;
      if (remote == null) return;

      // 只收「對方→我」或（必要時）「我→對方」的 echo
      final isThisTalk = (fromUid == remote && toUid == myUid) ||
          (fromUid == myUid   && toUid == remote);
      if (!isThisTalk) {
        debugPrint('[LIVE] skip: pair mismatch from=$fromUid to=$toUid me=$myUid remote=$remote');
        return;
      }

      // --- 去重（uuid）---
      String? uuid;
      final u = (payload['uuid'] ?? payload['UUID'] ?? data['uuid'] ?? data['UUID'] ?? '').toString();
      if (u.isNotEmpty) {
        uuid = u;
      }

      // --- 推進 UI ---
      final msg = ChatMessage(
        type: (fromUid == myUid) ? MessageType.self : MessageType.other,
        contentType: ChatContentType.text,
        text: chatText,
        uuid: uuid,
        createAt: cu.nowSec(),
      );

      ref.read(callSessionProvider(roomId).notifier).addIncoming(msg);
      _scrollLiveToBottom();
    } catch (e, st) {
      debugPrint('room chat (type=3) parse err: $e\n$st\npayload=$payload');
    }
  }

  Future<void> _sendLiveText() async {
    _liveInputFocus.unfocus();
    final txt = _liveInputCtrl.text.trim();
    if (txt.isEmpty) return;

    // 對方 uid 從 remoteUids 取（你提的需求）
    if (_remoteUids.isEmpty) {
      Fluttertoast.showToast(msg: '尚未連線到對方');
      return;
    }
    final toUid = _remoteUids.first;

    final user = ref.read(userProfileProvider);
    final myUid = int.tryParse(user?.uid ?? '');
    if (myUid == null) {
      Fluttertoast.showToast(msg: '尚未登入');
      return;
    }

    final uuid = cu.genUuid(myUid);
    final session = ref.read(callSessionProvider(roomId).notifier);

    // 樂觀加入一條 sending
    final optimistic = ChatMessage(
      type: MessageType.self,
      contentType: ChatContentType.text,
      text: txt,
      uuid: uuid,
      flag: 'chat_room', // 只是記錄，實際 API 會用
      toUid: toUid,
      sendState: SendState.sending,
      createAt: cu.nowSec(),
    );
    // 加入樂觀訊息
    session.addOptimistic(optimistic);
    _liveInputCtrl.clear();
    _scrollLiveToBottom();

    final repo = ref.read(chatRepositoryProvider);
    final ok = await repo.sendText(
      uuid: uuid,
      toUid: toUid,
      text: txt,
      flag: 'chat_room',
    );

    if (!mounted) return;
    session.updateSendState(uuid, ok ? SendState.sent : SendState.failed);
  }

  void _scrollLiveToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_liveScroll.hasClients) return;
      // reverse:true → 貼底 = 0.0，不是 maxScrollExtent
      final atBottom = _liveScroll.position.pixels <= 40;
      if (!atBottom) {
        _liveScroll.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _applyCallFlagFromArgs(Map<String, dynamic> args) {
    // 優先吃 callFlag (1=video, 2=voice)
    final int callFlag = (args['callFlag'] as int?) ??
        ((args['isVideoCall'] == true) ? 1 : 2); // fallback 舊參數

    _callType = (callFlag == 1) ? CallType.video : CallType.voice;
  }
}

enum CallType { video, voice }