import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/error_handler.dart';
import '../../core/ws/ws_provider.dart';
import '../../globals.dart';
import '../../routes/app_routes.dart';
import '../call/call_repository.dart';
import '../live/data_model/call_overlay.dart';
import '../live/mini_call_view.dart';
import '../profile/profile_controller.dart';
import '../widgets/cached_network_image.dart';
import 'call_abort_provider.dart';

class IncomingCallPage extends ConsumerStatefulWidget {
  final String channelName;
  final int fromUid; // 對方 uid（僅顯示）
  final int toUid; // 自己 uid（不用）
  final String callerName;
  final String callerAvatar;
  final String rtcToken; // 可能為空；接聽時一定再向 API 拿
  final String? callId; // 不再使用
  final int callerFlag; // 1=video, 2=voice, 來電 WS 的 flag

  const IncomingCallPage({
    super.key,
    required this.channelName,
    required this.fromUid,
    required this.toUid,
    required this.callerName,
    required this.callerAvatar,
    required this.rtcToken,
    this.callId,
    this.callerFlag = 1,
  });

  @override
  ConsumerState<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends ConsumerState<IncomingCallPage>
    with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<VoidCallback> _wsUnsubs = [];
  Timer? _timeoutTimer;
  bool _busy = false;

  BuildContext get _rootCtx => Navigator.of(context, rootNavigator: true).context;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _startRingtone();
    _listenWs();
    _startTimeout();
    WakelockPlus.enable();

    // ★ 啟動時立即檢查是否已被中止
    if (ref.read(callAbortProvider).contains(widget.channelName)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _endWithToast('對方已結束通話請求...');
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermsOnEnter();   // ⬅️ 頁面開啟就彈系統權限
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    for (final u in _wsUnsubs) { try { u(); } catch (_) {} }
    _wsUnsubs.clear();
    _timeoutTimer?.cancel();

    _audioPlayer.stop();
    _audioPlayer.dispose();

    WakelockPlus.disable();

    _hideMiniIfAny();
    super.dispose();
  }

  Future<void> _requestPermsOnEnter() async {
    final needCam = (widget.callerFlag == 1); // 視訊才需要相機
    final req = <Permission>[Permission.microphone, if (needCam) Permission.camera];

    final results = await req.request();
    final micOk = (results[Permission.microphone] == PermissionStatus.granted);
    final camOk = !needCam || (results[Permission.camera] == PermissionStatus.granted);

    final granted = micOk && camOk;
    if (!granted && mounted) {
      // 可選：若永久拒絕，可引導去系統設定
      final perma = results.values.any((s) => s == PermissionStatus.permanentlyDenied);
      if (perma) {
        // 這兩行二選一：要不要直接帶去系統設定由你決定
        // await openAppSettings();
        // return;
      }

      // 停掉鈴聲 / 釋放喚醒，然後關頁 + toast
      try { await _audioPlayer.stop(); } catch (_) {}
      unawaited(WakelockPlus.disable());
      Fluttertoast.showToast(msg: '請先授權相機與麥克風');

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        _backToHome(); // 沒有上一頁就回首頁
      }
    }
  }

  void _goMini() {
    CallOverlay.show(
      navigatorKey: rootNavigatorKey,
      child: MiniCallView(
        rootContext: rootNavigatorKey.currentContext!,
        roomId: widget.channelName,
        isVoice: widget.callerFlag != 1,
        remoteUid: widget.fromUid,
        onExpand: () => CallOverlay.hide(),
        // 如要在小窗能拒接：onHangup: () async => _reject(toast: '已拒絕來電'),
      ),
    );
    // 可選：把首頁頂上來，讓本頁留在棧中持續聽 WS
    Navigator.of(rootNavigatorKey.currentContext!).pushNamed(AppRoutes.home);
  }

  // ====== WS & 超時 ======
  Map<String, dynamic> _dataOf(Map p) =>
      (p['data'] is Map) ? Map<String, dynamic>.from(p['data']) : const {};

  String _ch(Map p) => _dataOf(p)['channel_id']?.toString() ?? '';

  int? _asInt(dynamic v) =>
      (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '');

  int? _status(Map p) => _asInt(_dataOf(p)['status']);

  bool _sameChannel(Map p) => _ch(p) == widget.channelName;

  void _listenWs() {
    final ws = ref.read(wsProvider);

    // 主叫取消/拒絕：call.accept(status=2) 或 invite(status=2)
    _wsUnsubs.add(ws.on('call.accept', (p) {
      if (!_sameChannel(p) || _busy) return;
      if (_status(p) == 2) _endWithToast('對方已結束通話請求...');
    }));
    _wsUnsubs.add(ws.on('call.invite', (p) {
      if (!_sameChannel(p) || _busy) return;
      if (_status(p) == 2) _endWithToast('對方已結束通話請求...');
    }));
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () async {
      if (!mounted || _busy) return;
      await _reject(toast: '來電超時未接');
    });
  }

  Future<void> _startRingtone() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('ringtone.wav'));
  }

  Future<void> _endWithToast(String msg) async {
    if (_busy) return;
    _busy = true;

    _timeoutTimer?.cancel();
    for (final u in _wsUnsubs) { try { u(); } catch (_) {} }
    _wsUnsubs.clear();

    if (msg.isNotEmpty) Fluttertoast.showToast(msg: msg);

    unawaited(_audioPlayer.stop());
    unawaited(WakelockPlus.disable());

    await _closeMiniIfAny();   // ★ 關小窗
    _backToHome();             // ★ 清棧回首頁
  }

  Future<void> _reject({String? toast}) async {
    if (_busy) return;
    _busy = true;

    _timeoutTimer?.cancel();
    for (final u in _wsUnsubs) { try { u(); } catch (_) {} }
    _wsUnsubs.clear();

    if (toast?.isNotEmpty == true) Fluttertoast.showToast(msg: toast!);

    unawaited(ref.read(callRepositoryProvider)
        .respondCall(channelName: widget.channelName, callId: widget.callId, accept: false)
        .timeout(const Duration(seconds: 2)).catchError((e) {
      AppErrorToast.show(e); // 非 alsoOk 的錯誤才會到這裡
    }));

    unawaited(_audioPlayer.stop());
    unawaited(WakelockPlus.disable());

    await _closeMiniIfAny();   // ★ 關小窗
    _backToHome();             // ★ 清棧回首頁
  }

  Future<void> _accept() async {
    if (_busy) return;
    _busy = true;

    // ★ 起手式：先看是否已被中止
    if (ref.read(callAbortProvider).contains(widget.channelName)) {
      _endWithToast('對方已結束通話請求...');
      return;
    }

    _timeoutTimer?.cancel();
    unawaited(_audioPlayer.stop());

    // 依雙方意願決定型態（只要一方不要就走語音）
    final mePrefVideo = ref.read(userProfileProvider)?.isVideoCall ?? true;
    final wantVideo   = mePrefVideo && (widget.callerFlag == 1);
    final needCam     = wantVideo;

    final req = <Permission>[Permission.microphone, if (needCam) Permission.camera];
    final statuses = await req.request();
    final micOk = statuses[Permission.microphone] == PermissionStatus.granted;
    final camOk = !needCam || statuses[Permission.camera] == PermissionStatus.granted;
    if (!micOk || !camOk) {
      _busy = false;
      Fluttertoast.showToast(msg: '請先授權麥克風${needCam ? "與相機" : ""}');
      return;
    }

    // 告知後端我接聽；若 invite 已帶 token 可直接用它
    String? token = (widget.rtcToken.isNotEmpty) ? widget.rtcToken : null;
    final acceptFuture = ref
        .read(callRepositoryProvider)
        .respondCall(
      channelName: widget.channelName,
      callId: widget.callId,
      accept: true,
    )
        .timeout(const Duration(seconds: 3))
        .catchError((e) {
      // 統一錯誤處理（常見錯誤碼給特別文案，其他交給字典）
      if (e is ApiException) {
        switch (e.code) {
          case 102: // Insufficient Quota
            Fluttertoast.showToast(msg: '餘額不足, 請前往充值～');
            break;
          case 121: // The User Is On Calling
            Fluttertoast.showToast(msg: '對方忙線中');
            break;
          case 123: // User Offline
            Fluttertoast.showToast(msg: '對方不在線');
            break;
          case 125: // Do Not Disturb
            Fluttertoast.showToast(msg: '對方開啟免擾');
            break;
          default:
            AppErrorToast.show(e);
        }
      } else {
        AppErrorToast.show(e);
      }
      return null; // 告訴後續：接聽失敗
    });

    if (token == null) {
      final resp = await acceptFuture;
      if (resp == null) {
        // 已於上方 catchError 顯示過錯誤訊息，這裡只結束流程即可
        _busy = false;
        return;
      }
      final data = (resp['data'] is Map)
          ? Map<String, dynamic>.from(resp['data'])
          : const <String, dynamic>{};
      token = (data['string'] ?? data['token'])?.toString();
      if (token == null || token.isEmpty) {
        _busy = false;
        Fluttertoast.showToast(msg: '接聽失敗：缺少通話憑證');
        return;
      }
    } else {
      // 已有 token，仍把接聽請求送出去（失敗會在 catchError 吐司，但不阻斷導頁）
      unawaited(acceptFuture);
    }

    // ★ 取得 token 之後、導航前再檢一次通話是否被終止
    if (!mounted || ref.read(callAbortProvider).contains(widget.channelName)) {
      _endWithToast('對方已結束通話請求...');
      return;
    }

    if (!mounted) return;
    final me = ref.read(userProfileProvider)!;

    // 進房
    Navigator.of(context).pushReplacementNamed(
      AppRoutes.broadcaster,
      arguments: {
        'roomId'       : widget.channelName,
        'token'        : token,
        'uid'          : me.uid,
        'title'        : widget.callerName,
        'hostName'     : me.displayName,
        'isCallMode'   : true,
        'asBroadcaster': true,
        'remoteUid'    : widget.fromUid,
        'callFlag'     : wantVideo ? 1 : 2,
        'peerAvatar'   : widget.callerAvatar,
      },
    );

    _hideMiniIfAny();

    // 若此時在 Mini → 關掉
    if (CallOverlay.isShowing) CallOverlay.hide();
  }

  void _hideMiniIfAny() {
    if (CallOverlay.isShowing) {
      try { CallOverlay.hide(); } catch (_) {}
    }
  }

  Future<void> _closeMiniIfAny() async {
    if (CallOverlay.isShowing) {
      CallOverlay.hide();
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  void _backToHome() {
    final nav = Navigator.of(_rootCtx);
    nav.pushNamedAndRemoveUntil(AppRoutes.home, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    // ★ 持續監聽通話是否被中止
    ref.listen<Set<String>>(callAbortProvider, (prev, next) {
      if (next.contains(widget.channelName)) {
        _endWithToast('對方已結束通話請求...');
      }
    });

    return WillPopScope(
      onWillPop: () async {
        _goMini();            // 返回鍵 → App 內 Mini
        return false;
      },
      child: Scaffold(
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
                    buildAvatarCircle(url: widget.callerAvatar, radius: 54),
                    const SizedBox(height: 16),
                    Text(
                      widget.callerName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.callerFlag == 1 ? '邀請您進行視頻通話' : '邀請您進行語音通話',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
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
                          child: SvgPicture.asset(widget.callerFlag == 1 ?'assets/call_live_accept.svg': 'assets/call_voice_accept.svg', width: 64, height: 64),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 左上縮小 → 進 App 內 Mini（與直播/撥打頁一致）
            Positioned(
              top: top + 8,
              left: 8,
              child: IconButton(
                icon: Image.asset('assets/zoom.png', width: 20, height: 20),
                onPressed: _goMini,
                tooltip: '縮小畫面',
                splashRadius: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

