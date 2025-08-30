import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/ws/ws_provider.dart';
import '../../routes/app_routes.dart';
import '../call/call_repository.dart';
import '../profile/profile_controller.dart';

class IncomingCallPage extends ConsumerStatefulWidget {
  final String channelName;
  final int fromUid;      // 對方 uid（僅顯示）
  final int toUid;        // 自己 uid（不用）
  final String callerName;
  final String callerAvatar;
  final String rtcToken;  // 可能為空；接聽時一定再向 API 拿
  final String? callId;   // 不再使用

  const IncomingCallPage({
    super.key,
    required this.channelName,
    required this.fromUid,
    required this.toUid,
    required this.callerName,
    required this.callerAvatar,
    required this.rtcToken,
    this.callId,
  });

  @override
  ConsumerState<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends ConsumerState<IncomingCallPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<VoidCallback> _wsUnsubs = [];
  Timer? _timeoutTimer;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startRingtone();
    _listenWs();
    _startTimeout();
    WakelockPlus.enable();
  }

  Future<void> _startRingtone() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('ringtone.wav'));
  }

  Map<String, dynamic> _dataOf(Map p) =>
      (p['data'] is Map) ? Map<String, dynamic>.from(p['data']) : const {};

  String _ch(Map p) => _dataOf(p)['channel_id']?.toString() ?? '';
  int? _asInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '');
  int? _status(Map p) => _asInt(_dataOf(p)['status']);

  bool _sameChannel(Map p) => _ch(p) == widget.channelName;

  void _listenWs() {
    final ws = ref.read(wsProvider);

    // 後端：call.accept + data.status=2 代表主叫取消/拒絕，關頁
    _wsUnsubs.add(ws.on('call.accept', (p) {
      if (!_sameChannel(p) || _busy) return;
      if (_status(p) == 2) _endWithToast('對方已結束通話請求...');
    }));

    // 若仍可能用 invite(status=2) 通知，也一併處理
    _wsUnsubs.add(ws.on('call.invite', (p) {
      if (!_sameChannel(p) || _busy) return;
      if (_status(p) == 2) _endWithToast('對方已結束通話請求...');
    }));
  }

  Future<void> _endWithToast(String msg) async {
    if (_busy) return;
    _busy = true;
    _timeoutTimer?.cancel();
    Fluttertoast.showToast(msg: msg);
    await _audioPlayer.stop();
    await WakelockPlus.disable();
    if (mounted) Navigator.of(context).pop();
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () async {
      if (!mounted || _busy) return;
      await _reject(toast: '來電超時未接');
    });
  }

  Future<void> _reject({String? toast}) async {
    if (_busy) return;
    _busy = true;
    try {
      await ref.read(callRepositoryProvider).respondCall(
        channelName: widget.channelName,
        callId: widget.callId,
        accept: false, // flag=2
      );
    } catch (_) {
      // ignore
    } finally {
      if (toast != null && toast.isNotEmpty) {
        Fluttertoast.showToast(msg: toast);
      }
      await _audioPlayer.stop();
      await WakelockPlus.disable();
      if (mounted) Navigator.of(context).pop();
    }
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

  Future<void> _accept() async {
    if (_busy) return;
    _busy = true;
    try {
      await [Permission.microphone, Permission.camera].request();
      await _audioPlayer.stop();

      // 被叫接通：一定要 await 取 token（很多情況 invite 的 string 為空）
      final resp = await ref.read(callRepositoryProvider).respondCall(
        channelName: widget.channelName,
        callId: widget.callId,
        accept: true, // flag=1
      );

      _timeoutTimer?.cancel();

      final data = (resp['data'] is Map) ? Map<String, dynamic>.from(resp['data']) : const {};
      final token = (data['string'] ?? data['token'] ?? widget.rtcToken)?.toString() ?? '';
      if (token.isEmpty) {
        throw '缺少通話 token';
      }

      final mUser = ref.read(userProfileProvider);
      if (!mounted) return;

      _debugCallArgs(
        from: 'CALLER', // 或 'CALLEE'
        channelId: widget.channelName,
        token: token, // 接收端用 invite.data.string；若空就沿用舊值
        myUid: int.parse(mUser!.uid),
        remoteUid: widget.fromUid,
      );
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.broadcaster,
        arguments: {
          'roomId'       : widget.channelName, // ← 跟 data.channel_id 一致
          'token'        : token,              // ← 被叫 token
          'uid'          : mUser!.uid,                  // 你的本地 uid
          'title'        : widget.callerName,
          'hostName'     : mUser.displayName,
          'isCallMode'   : true,
          'asBroadcaster': true,
          'remoteUid'    : widget.fromUid,
        },
      );
    } catch (e) {
      _busy = false;
      if (!mounted) return;
      Fluttertoast.showToast(msg: '接聽失敗：$e');
    }
  }

  @override
  void dispose() {
    for (final u in _wsUnsubs) { try { u(); } catch (_) {} }
    _timeoutTimer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final avatar = (widget.callerAvatar.isEmpty)
        ? const AssetImage('assets/my_icon_defult.jpeg') as ImageProvider
        : NetworkImage(widget.callerAvatar);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/bg_calling.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.45))),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: top + 24, bottom: 32),
              child: Column(
                children: [
                  const SizedBox(height: 110),
                  CircleAvatar(radius: 54, backgroundImage: avatar),
                  const SizedBox(height: 16),
                  Text(widget.callerName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('邀請您進行視頻通話', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 140),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _reject,
                        child: SvgPicture.asset('assets/call_end.svg', width: 64, height: 64),
                      ),
                      const SizedBox(width: 64),
                      GestureDetector(
                        onTap: _accept,
                        child: SvgPicture.asset('assets/call_live_accept.svg', width: 64, height: 64),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 8, left: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _reject,
              tooltip: '拒絕',
            ),
          ),
        ],
      ),
    );
  }
}
