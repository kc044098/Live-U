import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';


import '../../core/ws/ws_provider.dart';
import '../../routes/app_routes.dart';
import '../../config/app_config.dart';
import '../call/call_repository.dart';
import '../../core/ws/ws_service.dart';
import '../profile/profile_controller.dart';

/// 來電接聽頁（被叫端）
/// - 必要：callerName, callerAvatar, channelName 或 callId
/// - 若後端 WS payload 有 call_id，請帶進來（接受/拒絕 API 比較乾淨）
/// - 若暫無 call_id，也支援 fallback 以 channelName + uid 續 token 的做法（看你們後端是否提供）
class IncomingCallPage extends ConsumerStatefulWidget {
  final String channelName;
  final int fromUid;
  final int toUid;
  final String callerName;
  final String callerAvatar;
  final String rtcToken;
  final String? callId; // ✅ 用於 accept/reject

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
    // 亮屏避免待機
    WakelockPlus.enable();
  }

  Future<void> _startRingtone() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop); // 迴圈
    await _audioPlayer.play(AssetSource('ringtone.wav')); // 路徑要跟 pubspec 一致
  }

  void _listenWs() {
    final ws = ref.read(wsProvider);

    // 主叫取消 / 超時 / 結束 → 關閉頁
    _wsUnsubs.add(ws.on('call.cancel', (_) => _end('對方已取消')));
    _wsUnsubs.add(ws.on('call.timeout', (_) => _end('通話已超時')));
    _wsUnsubs.add(ws.on('call.end', (_) => _end('通話已結束')));
    _wsUnsubs.add(ws.on('call.busy',  (_) => _end('對方忙線中')));
  }

  Future<void> _endWithToast(String msg) async {
    if (_busy) return;          // 已接/已拒/正在處理就不重複結束
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
      if (!mounted || _busy) return; // 被按了接聽/拒絕就不處理

      await _endWithToast('來電未接通'); // ← 指定的文字
    });
  }

  Future<void> _end(String msg) async {
    if (!mounted) return;
    if (!_busy) {
      _busy = true;
      _timeoutTimer?.cancel();
      Fluttertoast.showToast(msg: msg);
    }
    await _audioPlayer.stop();
    await WakelockPlus.disable();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _reject() async {
    if (_busy) return;
    _busy = true;
    try {
      await ref.read(callRepositoryProvider).respondCall(
        channelName: widget.channelName,
        accept: false, // flag=2
      );
    } catch (_) {
      // 後端不回資料，錯誤可忽略
    } finally {
      if (mounted) {
        Fluttertoast.showToast(msg: '已拒絕');
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _accept() async {
    if (_busy) return;
    _busy = true;
    try {
      await [Permission.microphone, Permission.camera].request();
      await _audioPlayer.stop();

      // 告知後端我已接聽（不等回傳）
      unawaited(ref.read(callRepositoryProvider).respondCall(
        channelName: widget.channelName,
        accept: true,
      ));

      _timeoutTimer?.cancel(); // 重要：取消逾時

      final myName = ref.read(userProfileProvider)?.displayName ?? '';
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.broadcaster,
        arguments: {
          'roomId'       : widget.channelName,
          'token'        : widget.rtcToken, // ← 直接用 invite WS 帶來的被叫 token
          'uid'          : widget.toUid,
          'title'        : widget.callerName,
          'hostName'     : myName,
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
    for (final u in _wsUnsubs) { u(); }
    _timeoutTimer?.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final imgProvider = (widget.callerAvatar.isEmpty)
        ? const AssetImage('assets/my_icon_defult.jpeg') as ImageProvider
        : CachedNetworkImageProvider(widget.callerAvatar);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 背景圖 + 遮罩
          Positioned.fill(child: Image.asset('assets/bg_calling.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.45))),

          // 內容
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: top + 24, bottom: 32),
              child: Column(
                children: [
                  const SizedBox(height: 110),
                  CircleAvatar(radius: 54, backgroundImage: imgProvider),
                  const SizedBox(height: 16),
                  Text(widget.callerName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('邀請您進行視頻通話', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 140),

                  // 底部兩顆按鈕：拒接 / 接聽
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 拒接（紅色）
                      GestureDetector(
                        onTap: _reject,
                        child: SvgPicture.asset('assets/call_end.svg', width: 64, height: 64,),
                      ),
                      const SizedBox(width: 64),
                      // 接聽（綠色）
                      GestureDetector(
                        onTap: _accept,
                        child: Container(
                          width: 66, height: 66,
                          decoration: const BoxDecoration(
                              color: Color(0xFF2ECC71), shape: BoxShape.circle),
                          child: Center(
                            child: SvgPicture.asset('assets/call_live_accept.svg', width: 28, height: 28),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 關閉（左上角）
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