import 'dart:async';

import 'package:djs_live_stream/features/call/rtc_engine_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/ws/ws_provider.dart';
import '../../routes/app_routes.dart';
import '../profile/profile_controller.dart';
import 'call_repository.dart';

import 'package:flutter_svg/flutter_svg.dart';

class CallRequestPage extends ConsumerStatefulWidget {
  final String broadcasterId;     // 對方 uid（顯示用）
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
  final List<VoidCallback> _wsUnsubs = [];
  final _rtc = RtcEngineManager();

  Timer? _timeoutTimer;

  String? _channelId;     // 新：一律使用 data.channel_id / data.channel_name
  String? _callerToken;   // 主叫 token（liveCall 回來）
  int? _callerUid;        // 我方 uid（若後端有回）
  int? _calleeUid;        // 對方 uid

  bool _finished = false;
  bool _cancelled = false;
  bool _sentCancel = false;

  static const String _kToastTimeout = '電話撥打超時，對方無回應';

  @override
  void initState() {
    super.initState();
    _playRingtone();
    _initiateCall();
    _listenSignaling();
  }

  Future<void> _playRingtone() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('ringtone.wav'));
  }

  Future<void> _initiateCall() async {
    try {
      await [Permission.microphone, Permission.camera].request();
      await WakelockPlus.enable();

      final resp = await ref.read(callRepositoryProvider).liveCall(
        flag: 1, // 1=視頻
        toUid: int.parse(widget.broadcasterId),
      );

      final Map<String, dynamic> data =
      (resp['data'] is Map) ? Map<String, dynamic>.from(resp['data']) : Map<String, dynamic>.from(resp);

      _channelId   = (data['channel_id'] ?? data['channel_name'] ?? data['channle_name'])?.toString();
      _callerToken = (data['string'] ?? data['token'])?.toString();
      _callerUid   = (data['from_uid'] as num?)?.toInt() ?? (data['uid'] as num?)?.toInt();
      _calleeUid   = (data['to_uid'] as num?)?.toInt();

      if (_channelId == null || _channelId!.isEmpty || _callerToken == null || _callerToken!.isEmpty) {
        throw '呼叫返回缺少必要欄位(channel/token)';
      }

      _startTimeout();
    } catch (e) {
      if (_cancelled) return;
      Fluttertoast.showToast(msg: "發起呼叫失敗：$e");
      if (mounted) Navigator.pop(context);
    }
  }

  // ---- WS helpers（只看 data.*）----
  Map<String, dynamic> _dataOf(Map p) =>
      (p['data'] is Map) ? Map<String, dynamic>.from(p['data']) : const {};

  int? _asInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '');

  String _ch(Map p) => _dataOf(p)['channel_id']?.toString() ?? '';
  int? _status(Map p) => _asInt(_dataOf(p)['status']); // 1=對方接通, 2=對方拒絕
  int? _peerUid(Map p) => _asInt(_dataOf(p)['uid']);

  bool _sameCall(Map p) {
    final ch = _ch(p);
    if (_channelId != null && _channelId!.isNotEmpty && ch.isNotEmpty) {
      return ch == _channelId;
    }
    // 退而求其次：用對方 uid（理論上不會走到）
    final peer = _peerUid(p);
    return (_calleeUid != null && peer == _calleeUid);
  }

  void _debugCallArgs({
    required String from,
    required String channelId,
    required String? token,
    required int myUid,
    required int remoteUid,
    String? uuid,
  }) {
    debugPrint('🔎[$from] JOIN PRECHECK '
        'uuid=$uuid ch=$channelId myUid=$myUid remoteUid=$remoteUid tokenLen=${token?.length ?? 0}');
    assert(channelId.isNotEmpty, 'channel_id 不可為空');
    assert(myUid != 0, 'myUid 不可為 0');
  }

  void _listenSignaling() {
    final ws = ref.read(wsProvider);
    bool _navigated = false;

    Future<void> _goToRoom() async {
      if (_cancelled || _finished || _navigated || !mounted) return;
      _navigated = true;
      _finished  = true;
      await _audioPlayer.stop();
      _timeoutTimer?.cancel();
      final myName = ref.read(userProfileProvider)?.displayName ?? '';

      _debugCallArgs(
        from: 'CALLER', // 或 'CALLEE'
        channelId: _channelId!,
        token: _callerToken, // 接收端用 invite.data.string；若空就沿用舊值
        myUid: _callerUid ?? 0,
        remoteUid: _calleeUid!,
      );


      Navigator.pushReplacementNamed(
        context,
        AppRoutes.broadcaster,
        arguments: {
          'roomId'       : _channelId,       // 用 channel_id 當房號
          'token'        : _callerToken,     // 主叫 token（liveCall 回）
          'uid'          : _callerUid ?? 0,
          'title'        : widget.broadcasterName,
          'hostName'     : myName,
          'isCallMode'   : true,
          'asBroadcaster': true,
          'remoteUid'    : _calleeUid,
        },
      );
    }

    // 只處理新事件：call.accept（status=1/2）
    _wsUnsubs.add(ws.on('call.accept', (p) async {
      if (_cancelled || !_sameCall(p)) return;
      final st = _status(p);
      if (st == 1) {
        await _goToRoom();
      } else if (st == 2) {
        await _endWithToast('對方已拒絕');
      }
    }));

    // 若後端仍可能用 invite 通知拒絕（status=2），也一併處理
    _wsUnsubs.add(ws.on('call.invite', (p) async {
      if (_cancelled || !_sameCall(p)) return;
      if (_status(p) == 2) {
        await _endWithToast('對方已拒絕');
      }
    }));
  }

  Future<void> _notifyCancelOnce() async {
    if (_sentCancel) return;
    _sentCancel = true;

    final channel = _channelId;
    if (channel == null || channel.isEmpty) return;

    try {
      await ref.read(callRepositoryProvider).respondCall(
        channelName: channel,
        callId: null,
        accept: false, // flag=2
      );
    } catch (_) {/* ignore */}
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () async {
      if (_cancelled) return;
      await _endWithToast(_kToastTimeout);
    });
  }

  Future<void> _endWithToast(String msg) async {
    if (_finished) return;
    _finished = true;

    for (final u in _wsUnsubs) { try { u(); } catch (_) {} }
    _wsUnsubs.clear();
    _timeoutTimer?.cancel();

    if (!_cancelled && msg.isNotEmpty) {
      Fluttertoast.showToast(msg: msg);
    }
    await _audioPlayer.stop();
    await _rtc.leave();

    if (!mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(AppRoutes.home);
    }
  }

  Future<void> _cancelByUser() async {
    if (_finished) return;
    _cancelled = true;
    await _notifyCancelOnce();  // fire-and-forget 也可
    await _endWithToast('');
  }

  @override
  void dispose() {
    if (_cancelled && !_sentCancel) {
      // 保底通知一次
      unawaited(_notifyCancelOnce());
    }
    _timeoutTimer?.cancel();
    for (final u in _wsUnsubs) { try { u(); } catch (_) {} }
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
        : NetworkImage(widget.broadcasterImage);

    return WillPopScope(
      onWillPop: () async { await _cancelByUser(); return false; },
      child: Scaffold(
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
                        onTap: _cancelByUser,
                        child: SvgPicture.asset('assets/call_end.svg', width: 64, height: 64),
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
                onPressed: _cancelByUser,
                tooltip: '取消通話',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
