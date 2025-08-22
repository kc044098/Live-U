import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:djs_live_stream/features/call/rtc_engine_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../config/app_config.dart';
import '../../core/ws/ws_provider.dart';
import '../../core/ws/ws_service.dart';
import '../../routes/app_routes.dart';
import '../profile/profile_controller.dart';
import 'call_repository.dart';

class CallRequestPage extends ConsumerStatefulWidget {
  final String broadcasterId;     // to_uid
  final String broadcasterName;
  final String broadcasterImage;

  const CallRequestPage({
    super.key,
    required this.broadcasterId,
    required this.broadcasterName,
    required this.broadcasterImage,
  });

  @override
  ConsumerState<CallRequestPage> createState() => _CallRequestPageState();
}

class _CallRequestPageState extends ConsumerState<CallRequestPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timeoutTimer;
  String? _channelName;
  String? _callerToken;
  int? _callerUid;
  int? _calleeUid;

  final List<VoidCallback> _wsUnsubs = [];

  // 依你的專案抽象（可改成你現有的單例/Provider）
  final _rtc = RtcEngineManager();

  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _playRingtone();
    _initiateCall();    // ① 發起呼叫（向後端建房+拿主叫Token）
    _listenSignaling(); // ② 監聽被叫 accept/reject/cancel/timeout
  }

  Future<void> _playRingtone() async {
    await Future.delayed(const Duration(milliseconds: 300));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('ringtone.wav'));
  }

  Future<void> _initiateCall() async {
    try {
      await [Permission.microphone, Permission.camera].request();
      await WakelockPlus.enable();

      // ① 建房 + 撥打方 token
      final data = await ref.read(callRepositoryProvider).liveCall(
        flag: 1,
        toUid: int.parse(widget.broadcasterId),
      );

      _channelName = (data['channel_name'] ?? data['channle_name']) as String;
      _callerToken = data['token'] as String;             // 撥打方 token
      _callerUid   = (data['from_uid'] as num).toInt();
      _calleeUid   = (data['to_uid'] as num).toInt();

      // ② 不導頁，維持「等待接聽」UI；由 _listenSignaling() 處理 accept
      debugPrint('[CALL] liveCall ok, waiting accept... channel=$_channelName tokenLen=${_callerToken?.length}');

      _startTimeout();
    } catch (e) {
      Fluttertoast.showToast(msg: "發起呼叫失敗：$e");
      if (mounted) Navigator.pop(context);
    }
  }

  void _listenSignaling() {
    final ws = ref.read(wsProvider);

    bool _navigated = false;
    // 在 _initiateCall() 內：_calleeUid = (data['to_uid'] as num).toInt();

    Future<void> _goToRoom() async {
      if (_finished || _navigated || !mounted) return;
      _finished = true;
      _navigated = true;
      await _audioPlayer.stop();
      _timeoutTimer?.cancel();

      final myName = ref.read(userProfileProvider)?.displayName ?? '';
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.broadcaster,
        arguments: {
          'roomId'       : _channelName,
          'token'        : _callerToken, // ← 主叫 token（liveCall 回來的）
          'uid'          : _callerUid,   // ← 主叫自己的 uid
          'title'        : widget.broadcasterName,
          'hostName'     : myName,
          'isCallMode'   : true,
          'asBroadcaster': true,
          'remoteUid'    : _calleeUid,   // 可選
        },
      );
    }

    bool _isThisCall(Map p) {
      // server 沒帶 channel 時，用 uid 對應：
      //   uid     = 對方（被叫）
      //   to_uid  = 我（主叫）
      final uid    = (p['uid'] as num?)?.toInt();
      final toUid  = (p['to_uid'] as num?)?.toInt();
      if (_callerUid == null) return true; // 沒取到自己 uid 就放行
      if (toUid != null && toUid != _callerUid) return false;
      // 也順便記住 callee
      if (uid != null) _calleeUid = uid;
      return true;
    }

    bool _isAccepted(Map p) {
      final s = p['state'] ?? p['data']?['state'];
      if (s == null) return false;
      if (s is num) return s.toInt() == 1;
      final ss = s.toString().toLowerCase();
      return ss == '1' || ss == 'accept' || ss == 'accepted';
    }

    // ✅ 情境 A：標準 accept 事件（若後端有派發）
    _wsUnsubs.add(ws.on('call.accept', (p) async {
      if (!_isThisCall(p)) return;
      debugPrint('[CALL][DIALER] call.accept → goToRoom');
      await _goToRoom();
    }));

    // ✅ 情境 B：你的案例：call.invite + data.state=1 代表「開始通話」
    _wsUnsubs.add(ws.on('call.invite', (p) async {
      if (!_isThisCall(p)) return;
      if (_isAccepted(p)) {
        debugPrint('[CALL][DIALER] call.invite(state=1) → goToRoom');
        await _goToRoom();
      }
    }));

    // 🔁 Fallback：有些服務只發 type=call + state=1
    _wsUnsubs.add(ws.on('call', (p) async {
      if (!_isThisCall(p)) return;
      if (_isAccepted(p)) {
        debugPrint('[CALL][DIALER] call(state=1) → goToRoom');
        await _goToRoom();
      }
    }));

    // ❌ 拒絕 / 取消 / 逾時
    _wsUnsubs.add(ws.on('call.reject', (_) => _endWithToast('對方已拒絕')));
    _wsUnsubs.add(ws.on('call.cancel', (_) => _endWithToast('對方已取消')));
    _wsUnsubs.add(ws.on('call.timeout', (_) => _endWithToast('對方未接聽')));
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () async {
      // 可選：通知後端取消通話
      // await ref.read(callRepositoryProvider).cancelCall(channelName: _channelName);
      await _endWithToast("對方未接聽");
    });
  }

  Future<void> _endWithToast(String msg) async {
    if (_finished) return;

    for (final u in _wsUnsubs) { try { u(); } catch (_) {} }
    _wsUnsubs.clear();

    Fluttertoast.showToast(msg: msg);
    await _audioPlayer.stop();
    await _rtc.leave();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = Navigator.of(context);
      if (nav.canPop()) {
        nav.pop();
      } else {
        // 假如這頁有時是第一層（例如由通知直接進來），pop 會是 no-op
        // 這裡做個保底導回首頁/列表（把路由名換成你專案的）
        nav.pushReplacementNamed(AppRoutes.home);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    for (final u in _wsUnsubs) {
      try { u(); } catch (_) {}
    }
    _wsUnsubs.clear();

    _audioPlayer.stop();
    _audioPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final imgProvider = (widget.broadcasterImage.isEmpty)
        ? const AssetImage('assets/my_icon_defult.jpeg') as ImageProvider
        : CachedNetworkImageProvider(widget.broadcasterImage);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/bg_calling.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.4))),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: topPadding + 24, bottom: 32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 160),
                    CircleAvatar(radius: 60, backgroundImage: imgProvider),
                    const SizedBox(height: 32),
                    Text(widget.broadcasterName, style: const TextStyle(fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 24),
                    const Text('正在接通中...', style: TextStyle(fontSize: 18, color: Colors.white)),
                    const SizedBox(height: 240),
                    GestureDetector(
                      onTap: () {
                        // ref.read(callRepositoryProvider).cancelCall(); 尚未實作 cancelCall
                        Navigator.pop(context);
                      },
                      child: SvgPicture.asset('assets/call_end.svg', width: 64, height: 64,),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: topPadding + 8, left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                // ref.read(callRepositoryProvider).cancelCall(); 尚未實作 cancelCall
                Navigator.pop(context);
              },
              tooltip: '取消通話',
            ),
          ),
        ],
      ),
    );
  }
}
