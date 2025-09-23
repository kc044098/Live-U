import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:djs_live_stream/features/live/video_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/ws/ws_provider.dart';
import '../../data/models/gift_item.dart';
import '../../globals.dart';
import '../../routes/app_routes.dart';
import '../call/call_repository.dart';
import '../call/rtc_engine_manager.dart';
import '../message/chat_message.dart';
import '../message/chat_providers.dart';
import '../message/chat_utils.dart' as cu;
import '../message/gift/gift_bottom_sheet.dart';
import '../message/gift/show_insufficient_gold_sheet.dart';
import '../profile/profile_controller.dart';
import 'call_session_provider.dart';
import 'data_model/call_overlay.dart';
import 'data_model/call_timer.dart';
import 'data_model/free_digits_badge.dart';
import 'data_model/gift_effect_player.dart';
import 'data_model/live_chat_input_bar.dart';
import 'data_model/live_chat_panel.dart';
import 'data_model/stable_remote_video_view.dart';
import 'gift_providers.dart';
import 'mini_call_view.dart';

class BroadcasterPage extends ConsumerStatefulWidget {
  const BroadcasterPage({super.key});

  @override
  ConsumerState<BroadcasterPage> createState() => _BroadcasterPageState();
}

class _BroadcasterPageState extends ConsumerState<BroadcasterPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
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
  int _freeAtSec = 0;

  bool _inFreePeriod = false;
  int _freeLeftSec = 0;
  Timer? _freeTimer;

  late final RtcEngineManager _rtc;
  late final VoidCallback _joinedListener;
  late final VoidCallback _remoteListener;

  // 文字聊天室
  late final TextEditingController _liveInputCtrl = TextEditingController();
  late final FocusNode _liveInputFocus = FocusNode();
  final ScrollController _liveScroll = ScrollController();

  final GlobalKey _localPreviewKey = GlobalKey();

  bool _speakerOn = true;
  bool _micOn = true;
  bool _videoOn = true;

  bool _frontCamera = true;

  bool _remoteVideoOn = true;
  late final RtcEngineEventHandler _pageRtcHandler;

  // 去重 WS 的 uuid（避免重放）
  final _liveSeenUuid = <String>{};

  late final GiftEffectPlayer _giftFx;

  Timer? _remoteGoneTimer;
  static const int _remoteGoneGraceSec = 5;

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


        if (_freeAtSec > 0) {
          // 有免費時長 → 主計時先不要跑
          ref.read(callTimerProvider).reset();
          _startFreeCountdown();        // 結束時會自動 start()
        } else {
          // 沒有免費時長 → 直接開始主計時
          ref.read(callTimerProvider).start();
        }
      }
    };

    // ② 改你的 _remoteListener：偵測遠端在/不在 & 啟停計時器
    _remoteListener = () {
      if (!mounted) return;

      setState(() {
        _remoteUids
          ..clear()
          ..addAll(_rtc.remoteUids.value);
      });

      final nowHasRemote = _remoteUids.isNotEmpty;

      // 只有在「我已加入房間」後才判斷對方
      if (_joined) {
        if (nowHasRemote) {
          _cancelRemoteGoneTimer();   // 對方回來（或本來就在）→ 取消計時
        } else {
          _armRemoteGoneTimer();      // 對方不在 → 開始 5 秒倒數
        }
      }
    };
    // 綁定全域通知
    _rtc.joined.addListener(_joinedListener);
    _rtc.remoteUids.addListener(_remoteListener);

    if (CallOverlay.isShowing) CallOverlay.hide();
    _giftFx = GiftEffectPlayer(vsync: this);
  }

  Future<void> _endBecauseRemoteLeft() async {
    if (_closing) return;
    _closing = true;

    _giftFx.stop(clearQueue: true);

    // 先停本地狀態與計時
    _cancelJoinTimeout();
    _stopFreeCountdown();
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

    await _goLiveEndIfBroadcaster();

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
      final freeRaw = args['free_at'] ?? args['freeAt'] ?? args['freeSec'];
      final fs = (freeRaw is num) ? freeRaw.toInt() : int.tryParse('${freeRaw ?? ''}');
      if (fs != null && fs >= 0) _freeAtSec = fs;
      _inFreePeriod = _freeAtSec > 0;
      _applyCallFlagFromArgs(args);
      _videoOn = !_isVoice;

      final s = ref.read(callSessionProvider(roomId));
      _liveInputCtrl.text = s.draft;
      _liveInputCtrl.removeListener(_onDraftChanged);
      _liveInputCtrl.addListener(_onDraftChanged);

      _argsReady = true;
      _enterRoom();
      _listenCallSignals();

      // 監聽遠端視訊開關
      _pageRtcHandler = RtcEngineEventHandler(
        // 新版事件
        onRemoteVideoStateChanged: (conn, uid, state, reason, elapsed) {
          if (conn.channelId != roomId || uid != _remoteUid) return;

          // 狀態判斷
          switch (state) {
            case RemoteVideoState.remoteVideoStateStarting:
            case RemoteVideoState.remoteVideoStateDecoding:
              _setRemoteVideoOn(true);
              break;
            case RemoteVideoState.remoteVideoStateStopped:
            // 真正被停止才關閉
              _setRemoteVideoOn(false);
              break;
            case RemoteVideoState.remoteVideoStateFrozen:
            case RemoteVideoState.remoteVideoStateFailed:
            // 這兩個多半是網路波動，先不要切頭像
            // 保持現狀，等恢復 Decoding 再自動變回 true
              break;
            default:
              break;
          }

          // 只有明確訊號才關閉/開啟
          if (reason == RemoteVideoStateReason.remoteVideoStateReasonRemoteMuted ||
              reason == RemoteVideoStateReason.remoteVideoStateReasonRemoteOffline) {
            _setRemoteVideoOn(false);
          }
          if (reason == RemoteVideoStateReason.remoteVideoStateReasonRemoteUnmuted ||
              reason == RemoteVideoStateReason.remoteVideoStateReasonNetworkRecovery) {
            _setRemoteVideoOn(true);
          }

        },
        // 到期前 ~30 秒觸發：先拿新 token 並續上去
        onTokenPrivilegeWillExpire: (conn, token) async {
          // 即將過期（通常提前 30 秒通知）
          if (conn.channelId == roomId) await _refreshToken();
        },
        onRequestToken: (conn) async {
          // SDK 主動要求 token（某些情況會觸發）
          if (conn.channelId == roomId) await _refreshToken();
        },
        onConnectionStateChanged: (conn, state, reason) {
          // 若因 token 過期導致斷線
          if (conn.channelId == roomId &&
              reason == ConnectionChangedReasonType.connectionChangedTokenExpired) {
            _refreshToken();
          }
        },
        onError: (code, msg) {
          // 保底：109=ERR_TOKEN_EXPIRED, 110=ERR_INVALID_TOKEN
          if (code == ErrorCodeType.errTokenExpired ||
              code == ErrorCodeType.errInvalidToken) {
            _refreshToken();
          }
        },

        // 舊版/相容事件
        onUserMuteVideo: (conn, uid, muted) {
          if (conn.channelId == roomId && uid == _remoteUid) _setRemoteVideoOn(!muted);
        },
        onUserEnableVideo: (conn, uid, enabled) {
          if (conn.channelId == roomId && uid == _remoteUid) _setRemoteVideoOn(enabled);
        },
      );
      _rtc.engine.registerEventHandler(_pageRtcHandler);
    } else {
      Navigator.of(context).pop();
    }
  }

  int? get _remoteUid => _remoteUids.isNotEmpty ? _remoteUids.first : null;

  void _setRemoteVideoOn(bool on) {
    if (!mounted || _remoteVideoOn == on) return;
    setState(() => _remoteVideoOn = on);
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

    _wsUnsubs.add(ws.on('live_chat', _onWsLiveChat));
    _wsUnsubs.add(ws.on('gift',      _onWsLiveChat));

  }

  /// 圖片按鈕：不加任何底色，圖片自帶圓底
  Widget _assetBtn({
    required String asset,         // 開啟時的圖
    String? offAsset,              // 關閉時的圖（可不給，改用透明度）
    required VoidCallback onTap,
    bool on = true,
  }) {
    final a = (offAsset != null && !on) ? offAsset : asset;
    return Opacity(
      opacity: on ? 1.0 : 0.55, // 沒 off 圖時用透明度表達
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.only(left: 10),
          alignment: Alignment.center,
          child: Image.asset(a, width: 32, height: 32, fit: BoxFit.contain),
        ),
      ),
    );
  }

  // === 新增：功能動作 ===
  Future<void> _toggleSpeaker() async {
    final nv = !_speakerOn;
    setState(() => _speakerOn = nv);
    try { await _rtc.engine.setEnableSpeakerphone(nv); } catch (_) {}
  }
  Future<void> _toggleMic() async {
    final nv = !_micOn;
    setState(() => _micOn = nv);
    try { await _rtc.engine.muteLocalAudioStream(!nv); } catch (_) {}
  }
  Future<void> _toggleVideo() async {
    // 語音模式就不處理
    if (_isVoice) return;

    final engine = _rtc.engine;
    if (engine == null) return;
    final next = !_videoOn;
    try {
      if (next) {
        // 開啟本地攝像頭 + 允許上行 + 開始預覽
        await engine.enableLocalVideo(true);
        await engine.muteLocalVideoStream(false);
        await engine.startPreview();
      } else {
        // 關閉本地攝像頭 + 停止上行 + 停止預覽
        await engine.muteLocalVideoStream(true);
        await engine.enableLocalVideo(false);
        await engine.stopPreview();
      }
      if (!mounted) return;
      setState(() => _videoOn = next);
    } catch (e) {
      debugPrint('[RTC] toggleVideo error: $e');
      Fluttertoast.showToast(msg: '切換影像失敗');
    }
  }
  Future<void> _switchCamera() async {
    if (_isVoice) return;                 // 語音模式禁用
    final engine = _rtc.engine;
    if (engine == null) return;

    try {
      await engine.switchCamera();        // Agora 一鍵切換
      if (!mounted) return;
      setState(() => _frontCamera = !_frontCamera); // 同步本地預覽鏡像
    } catch (e) {
      debugPrint('[RTC] switchCamera error: $e');
      Fluttertoast.showToast(msg: '切換鏡頭失敗');
    }
  }

  void _openGiftSheetLive() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => GiftBottomSheet(
        onSelected: (gift) async {
          final me = ref.read(userProfileProvider);
          if (_remoteUids.isEmpty) return false;
          final toUid = _remoteUids.first;

          // 立刻播特效（相對→完整）
          final effectUrl = cu.joinCdn(me?.cdnUrl, gift.url);
          _giftFx.enqueue(context, effectUrl);
          // 發送 payload（帶 gift_url，方便對端解析直接播）
          final payload = jsonEncode({
            'type': 'gift',
            'gift_id': gift.id,
            'gift_title': gift.title,
            'gift_gold': gift.gold,
            'gift_icon': gift.icon,   // 相對路徑
            'gift_count': 1,
            'gift_url': gift.url,     // 相對路徑（WS 也會帶給對端）
          });

          final myUid = int.tryParse(me?.uid ?? '0') ?? 0;
          final uuid  = cu.genUuid(myUid);

          // 樂觀加入面板（顯示 icon + 次數）
          final iconFull = cu.joinCdn(me?.cdnUrl, gift.icon);
          ref.read(callSessionProvider(roomId).notifier).addOptimistic(
            ChatMessage(
              type: MessageType.self,
              contentType: ChatContentType.gift,
              text: gift.title,
              uuid: uuid,
              flag: 'gift',
              toUid: toUid,
              data: {
                'gift_id': gift.id,
                'gift_title': gift.title,
                'gift_icon': iconFull,
                'gift_gold': gift.gold,
                'gift_count': 1,
                'gift_url': gift.url, // 相對
              },
              sendState: SendState.sending,
              createAt: cu.nowSec(),
            ),
          );
          _scrollLiveToBottom();

          // 真正發送（旗標用 chat_room）
          final sendResult = await ref.read(chatRepositoryProvider)
              .sendText(uuid: uuid, toUid: toUid, text: payload, flag: 'gift');

          ref.read(callSessionProvider(roomId).notifier)
              .updateSendState(uuid, sendResult.ok ? SendState.sent : SendState.failed);

          return sendResult.ok;
        },
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

    _giftFx.stop(clearQueue: true);

    // 後端規定：離開也用 respondCall(flag=2)
    final repo = ref.read(callRepositoryProvider);
    ref.read(callSessionProvider(roomId).notifier).clearAll();
    unawaited(
      repo.respondCall(
        channelName: roomId,
        callId: null,
        accept: false,
      ).timeout(const Duration(seconds: 2), onTimeout: () => <String, dynamic>{})
          .then<void>((_) {}, onError: (e) => debugPrint('[hangup] notify fail: $e')),
    );

    await _rtc.safeLeave();

    unawaited(WakelockPlus.disable());
    ref.read(callTimerProvider).reset();

    await _closeMiniIfAny();
    await _goLiveEndIfBroadcaster();
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

  Future<void> _goLiveEndIfBroadcaster() async {
    if (!ref.read(userProfileProvider)!.isBroadcaster) {
       _goHome();
       return;
    }

    // 取結算資料（失敗也會回傳全 0 的 LiveEndSummary）
    final liveEnd =
    await ref.read(videoRepositoryProvider).fetchLiveEnd(channelName: roomId);

    await _closeMiniIfAny();

    // 用 replace，避免返回到通話頁
    Navigator.of(rootNavigatorKey.currentContext ?? context, rootNavigator: true)
        .pushReplacementNamed(AppRoutes.live_end, arguments: liveEnd);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rtc.joined.removeListener(_joinedListener);
    _rtc.remoteUids.removeListener(_remoteListener);
    _cancelRemoteGoneTimer();

    try { _rtc.engine.unregisterEventHandler(_pageRtcHandler); } catch (_) {}

    _liveInputCtrl.dispose();
    _liveInputFocus.dispose();
    _liveScroll.dispose();

    _cancelJoinTimeout();
    for (final u in _wsUnsubs) {
      try {
        u();
      } catch (_) {}
    }
    _wsUnsubs.clear();
    _stopFreeCountdown();
    WakelockPlus.disable();
    _giftFx.dispose();
    super.dispose();
  }

  void _goMini() {

    _giftFx.stop(clearQueue: true);

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
      'free_at'      : _inFreePeriod ? _freeLeftSec : 0,
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
        _giftFx.stop(clearQueue: true);
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
            Positioned.fill(
              child: _isVoice
                  ? const ColoredBox(color: Colors.white)
                  : StableRemoteVideoView(
                engine: _rtc.engine,
                roomId: roomId,
                remoteUid: _remoteUid,
                remoteVideoOn: _remoteVideoOn,
                avatar: avatarProvider,
              ),
            ),

            // 左上：縮小（改成 App 內小窗）
            Positioned(
              top: top + 6,
              left: 12,
              child: IconButton(
                icon: Image.asset('assets/zoom.png', width: 20, height: 20, color: _isVoice? Color(0xFF8E8895) : Colors.white),
                onPressed: _goMini,
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

            // 名字下方：免費時長 / 計時膠囊（二擇一）
            Positioned(
              top: top + 56,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _joined ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: _inFreePeriod
                      ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '免費時長',
                        style: TextStyle(
                          color: fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: FreeDigitsBadge(
                          text: _mmss(_freeLeftSec),  // 01:10
                          fg: fg,
                          bg: chipBg,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _openRechargeSheetFromFreeBadge,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: const Text(
                            '去充值',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  )
                      : Container(
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
            if (!_isVoice && _videoOn)
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
                    child: StableLocalPreviewView(
                      engine: _rtc.engine, // 你的全域引擎
                      mirrorFront: _frontCamera, // 你現有的狀態
                      show: _videoOn, // 你現有的狀態（true 顯示預覽）
                      // 如果你不想讓元件幫忙 start/stopPreview，就設 false，
                      // 並保持你原本 _toggleVideo 的 Agora 呼叫：
                      manageLifecycle: true,
                    ),
                  ),
                ),
              ),

            // ====== 透明聊天紀錄框（左下，顯示最近訊息）======
            Positioned(
              left: 10,
              bottom: 110, // 留給輸入框高度
              child: LiveChatPanel(
                messages: ref.watch(callSessionProvider(roomId).select((s) => s.messages)),
                controller: _liveScroll,
                myName: mUser?.displayName ?? '用戶 ${_remoteUids.first}',
                peerName: title,
              ),
            ),

            // 快捷禮物列（輸入框正上方）
            Positioned(
              left: 12,
              bottom: 55, // 略高於輸入列（預留 SafeArea + 間距）
              child: SizedBox(
                width: 170,
                height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Consumer(
                      builder: (_, ref, __) {
                        final quickGifts = ref.watch(quickGiftListProvider);

                        return quickGifts.when(
                          loading: () => const Center(
                            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          error: (_, __) => const SizedBox.shrink(), // 靜默；不影響輸入與聊天
                          data: (list) {
                            if (list.isEmpty) return const SizedBox.shrink();

                            final cdnBase = ref.watch(userProfileProvider)?.cdnUrl ?? '';
                            // 只顯示 3 個寬度，但可以水平滑到更多
                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                              itemCount: list.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 6),
                              itemBuilder: (_, i) {
                                final g = list[i];
                                final icon = g.icon.startsWith('http') ? g.icon : cu.joinCdn(cdnBase, g.icon);
                                return InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => _sendQuickGift(g),
                                  child: Ink(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _isVoice ? Colors.white : const Color(0xFF0F0F10),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: (icon.isNotEmpty)
                                          ? Image.network(icon, fit: BoxFit.cover)
                                          : const SizedBox.shrink(),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // === 底部輸入 + 功能鍵（同一個 Positioned / 同一個 Row）===
            Positioned(
              left: 12,
              right: 12,
              bottom: 0, // 交給 SafeArea + 鍵盤 inset 處理
              child: SafeArea(
                bottom: true,
                // 最低想留的視覺間距（home indicator 上方再加 12）
                minimum: const EdgeInsets.only(bottom: 12),
                child: Builder(
                  builder: (context) {
                    final media = MediaQuery.of(context);
                    // 鍵盤彈出時，多墊出鍵盤高度（iOS 會自動動畫）
                    final keyboard = media.viewInsets.bottom;

                    return Padding(
                      padding: EdgeInsets.only(bottom: keyboard),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 輸入框（吃掉剩餘寬度）
                          Expanded(
                            child: LiveChatInputBar(
                              controller: _liveInputCtrl,
                              focusNode: _liveInputFocus,
                              onSend: _sendLiveText,
                              onTapField: () {},
                            ),
                          ),
                          const SizedBox(width: 20),

                          // 右側按鈕列（固定高度，和輸入框垂直置中）
                          _assetBtn(
                            asset: 'assets/icon_gift.png',
                            onTap: _openGiftSheetLive,
                          ),
                          _assetBtn(
                            asset: 'assets/icon_speaker_1.png',
                            offAsset: 'assets/icon_speaker_2.png',
                            onTap: _toggleSpeaker,
                            on: _speakerOn,
                          ),
                          _assetBtn(
                            asset: 'assets/icon_mic_1.png',
                            offAsset: 'assets/icon_mic_2.png',
                            onTap: _toggleMic,
                            on: _micOn,
                          ),
                          if (!_isVoice)
                            _assetBtn(
                              asset: 'assets/icon_vedio.png',
                              onTap: _toggleVideo,
                              on: _videoOn,
                            ),
                          if (!_isVoice && _videoOn)
                            _assetBtn(
                              asset: 'assets/icon_switch.png',
                              onTap: _switchCamera,
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            )

          ],
        ),
      ),
    );
  }

  void _openRechargeSheetFromFreeBadge() async {
    await showInsufficientGoldSheet(
      context,
      ref,
      onRechargeTap: (int? amount) {
      },
      suggestedAmount: null, // ★ 與禮物面板底部「儲值」按鈕一致
    );
  }

  Map<String, dynamic>? _decodeJsonMap(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      final v = jsonDecode(s);
      if (v is Map) return v.map((k, v) => MapEntry(k.toString(), v));
    } catch (_) {}
    return null;
  }
  int _toInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('${v ?? ''}') ?? -1;
  String _joinCdn(String base, String path) {
    if (path.isEmpty || path.startsWith('http')) return path;
    final b = base.replaceFirst(RegExp(r'/+$'), '');
    final p = path.replaceFirst(RegExp(r'^/+'), '');
    return '$b/$p';
  }

  void _onWsLiveChat(Map<String, dynamic> payload) {
    if (!mounted || _closing) return;  // ★ 避免頁面關閉後還處理
    try {
      final data = (payload['Data'] is Map)
          ? Map<String, dynamic>.from(payload['Data'])
          : (payload['data'] is Map)
          ? Map<String, dynamic>.from(payload['data'])
          : const <String, dynamic>{};

      // 保險型過濾：只收 live_chat（flag/type=3）
      final tRaw = payload['type'] ?? payload['Type'] ?? payload['flag'] ?? payload['Flag'];
      final tVal = (tRaw is num) ? tRaw.toInt() : int.tryParse('$tRaw');
      if (tVal != null && tVal != 3 && tVal != 1) return;

      final content = (data['Content'] ?? data['content'] ?? '').toString();
      if (content.isEmpty) return;

      // 第一層：content 可能是 {"chat_text":"..."} / {"voice_path":...}
      final cjson = _decodeJsonMap(content);
      String? chatText = cjson?['chat_text']?.toString() ?? content;
      String? voiceRel = cjson?['voice_path']?.toString();
      int duration = () {
        final d = cjson?['duration'];
        return (d is num) ? d.toInt() : int.tryParse('${d ?? ''}') ?? 0;
      }();

      final me = ref.read(userProfileProvider);
      final myUid = int.tryParse(me?.uid ?? '') ?? -1;
      final fromUid = _toInt(data['Uid'] ?? payload['Uid'] ?? data['uid'] ?? payload['uid']);
      final toUid   = _toInt(data['ToUid'] ?? payload['ToUid'] ?? data['to_uid'] ?? payload['toUid']);

      final remote = _remoteUids.isNotEmpty ? _remoteUids.first : null;
      if (remote == null) return;

      final isThisTalk = (fromUid == remote && toUid == myUid) ||
          (fromUid == myUid   && toUid == remote);
      if (!isThisTalk) return;

      final uuid = (payload['uuid'] ?? payload['UUID'] ?? data['uuid'] ?? data['UUID'] ?? '').toString();
      if (uuid.isNotEmpty && !_liveSeenUuid.add(uuid)) return;
      final now  = cu.nowSec();

      // ★ 第二層：chat_text 可能是字串化的禮物 JSON
      final inner = _decodeJsonMap(chatText);
      final innerType = (inner?['type'] ?? inner?['t'])?.toString().toLowerCase();

      final session = ref.read(callSessionProvider(roomId).notifier);
      final cdnBase = me?.cdnUrl ?? '';

      if (innerType == 'gift') {
        final gid   = _toInt(inner?['gift_id'] ?? inner?['id']);
        final title = (inner?['gift_title'] ?? inner?['title'] ?? '').toString();
        final iconRel = (inner?['gift_icon'] ?? inner?['icon'] ?? '').toString();
        final gold  = _toInt(inner?['gift_gold'] ?? inner?['gold']);
        final count = _toInt(inner?['gift_count'] ?? inner?['count']);
        String urlRel = (inner?['gift_url'] ?? '').toString();

        // 若缺 gift_url，靠本地禮物表補
        if (urlRel.isEmpty && gid >= 0) {
          final gifts = ref.read(giftListProvider).maybeWhen(
            data: (v) => v,
            orElse: () => const <GiftItemModel>[],
          );
          final g = gifts.where((e) => e.id == gid).toList();
          if (g.isNotEmpty && g.first.url.isNotEmpty) {
            urlRel = g.first.url; // 相對
          }
        }

        final iconFull = _joinCdn(cdnBase, iconRel);
        final urlFull  = _joinCdn(cdnBase, urlRel);

        if (fromUid != myUid && urlFull.isNotEmpty) {
          _giftFx.enqueue(context, urlFull);
        }

        final msg = ChatMessage(
          type: (fromUid == myUid) ? MessageType.self : MessageType.other,
          contentType: ChatContentType.gift,
          text: title,
          uuid: uuid.isEmpty ? null : uuid,
          createAt: now,
          data: {
            'gift_id': gid,
            'gift_title': title,
            'gift_icon': iconFull,
            'gift_gold': gold,
            'gift_count': count,
            if (urlRel.isNotEmpty) 'gift_url': urlFull,
          },
        );

        session.addIncoming(msg);
        _scrollLiveToBottom();

        return;
      }

      // 語音訊息（若你的直播面板有要顯示就補 UI；下方先保持文字為主）
      if ((voiceRel ?? '').isNotEmpty) {
        final msg = ChatMessage(
          type: (fromUid == myUid) ? MessageType.self : MessageType.other,
          contentType: ChatContentType.voice,
          audioPath: _joinCdn(cdnBase, voiceRel!),
          duration: duration,
          uuid: uuid.isEmpty ? null : uuid,
          createAt: now,
        );
        session.addIncoming(msg);
        _scrollLiveToBottom();
        return;
      }

      // 純文字
      final msg = ChatMessage(
        type: (fromUid == myUid) ? MessageType.self : MessageType.other,
        contentType: ChatContentType.text,
        text: chatText ?? '',
        uuid: uuid.isEmpty ? null : uuid,
        createAt: now,
      );
      session.addIncoming(msg);
      _scrollLiveToBottom();
    } catch (e, st) {
      debugPrint('[LIVE WS] parse err: $e\n$st\npayload=$payload');
    }
  }

  String _mmss(int sec) {
    if (sec < 0) sec = 0;
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startFreeCountdown() {
    _freeTimer?.cancel();
    setState(() {
      _inFreePeriod = _freeAtSec > 0;
      _freeLeftSec = _freeAtSec;
    });
    if (!_inFreePeriod) return;

    _freeTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_freeLeftSec <= 1) {
        t.cancel();
        setState(() {
          _inFreePeriod = false;
          _freeLeftSec = 0;
        });
        // 免費結束 → 啟動原計時器
        ref.read(callTimerProvider).start();
        Fluttertoast.showToast(msg: '免費時長已結束，開始計費');
      } else {
        setState(() => _freeLeftSec--);
      }
    });
  }

  void _stopFreeCountdown() {
    _freeTimer?.cancel();
    _freeTimer = null;
  }

  void _armRemoteGoneTimer() {
    _cancelRemoteGoneTimer();
    _remoteGoneTimer = Timer(const Duration(seconds: _remoteGoneGraceSec), () async {
      if (!mounted || _closing) return;
      // 再確認一次確實沒人
      if (_rtc.remoteUids.value.isEmpty) {
        Fluttertoast.showToast(msg: '對方已離開直播間');
        await _endBecauseRemoteLeft(); // 已有離房邏輯
      }
    });
  }

  void _cancelRemoteGoneTimer() {
    _remoteGoneTimer?.cancel();
    _remoteGoneTimer = null;
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
    final sendResult = await repo.sendText(
      uuid: uuid,
      toUid: toUid,
      text: txt,
      flag: 'chat_room',
    );

    if (!mounted) return;
    session.updateSendState(uuid, sendResult.ok ? SendState.sent : SendState.failed);
  }

  Future<void> _sendQuickGift(GiftItemModel gift) async {
    if (_remoteUids.isEmpty) {
      Fluttertoast.showToast(msg: '尚未連線到對方');
      return;
    }
    final me = ref.read(userProfileProvider);
    final toUid = _remoteUids.first;

    // 立刻播放本地特效（把相對路徑補成完整 CDN）
    final effectUrl = cu.joinCdn(me?.cdnUrl, gift.url);
    if (effectUrl.isNotEmpty) {
      _giftFx.enqueue(context, effectUrl);
    }

    // 組裝 payload（與彈窗送禮一致，後端解析扣款）
    final payload = jsonEncode({
      'type': 'gift',
      'gift_id': gift.id,
      'gift_title': gift.title,
      'gift_gold': gift.gold,
      'gift_icon': gift.icon,   // 相對路徑
      'gift_count': 1,
      'gift_url': gift.url,     // 相對路徑
    });

    final myUid = int.tryParse(me?.uid ?? '0') ?? 0;
    final uuid  = cu.genUuid(myUid);
    final iconFull = cu.joinCdn(me?.cdnUrl, gift.icon);

    // 樂觀加入面板
    ref.read(callSessionProvider(roomId).notifier).addOptimistic(
      ChatMessage(
        type: MessageType.self,
        contentType: ChatContentType.gift,
        text: gift.title,
        uuid: uuid,
        flag: 'gift',
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
      ),
    );
    _scrollLiveToBottom();

    // 真正送出
    final sendResult = await ref.read(chatRepositoryProvider)
        .sendText(uuid: uuid, toUid: toUid, text: payload, flag: 'gift');

    if (!mounted) return;
    ref.read(callSessionProvider(roomId).notifier)
        .updateSendState(uuid, sendResult.ok ? SendState.sent : SendState.failed);

    if (!sendResult.ok) {
      Fluttertoast.showToast(msg: '送禮失敗，請稍後重試');
    }
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

  Future<void> _refreshToken() async {
    if (roomId.isEmpty) return;
    try {

      final newToken = await ref.read(callRepositoryProvider).renewRtcToken(
        channelName: roomId,
      );

      await _rtc.engine.renewToken(newToken);        // ✅ 回傳給 Agora
      setState(() => rtcToken = newToken);           // (可選)保留現值
      debugPrint('[RTC] token renewed');
    } catch (e) {
      debugPrint('[RTC] renew token error: $e');
      // 失敗策略（可選）：稍後重試/提示/視情況離房
    }
  }

  void _applyCallFlagFromArgs(Map<String, dynamic> args) {
    // 優先吃 callFlag (1=video, 2=voice)
    final int callFlag = (args['callFlag'] as int?) ??
        ((args['isVideoCall'] == true) ? 1 : 2); // fallback 舊參數

    _callType = (callFlag == 1) ? CallType.video : CallType.voice;
  }
}

enum CallType { video, voice }