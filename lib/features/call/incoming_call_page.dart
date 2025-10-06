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
import '../../l10n/l10n.dart';
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
        Fluttertoast.showToast(msg: S.of(context).callerEndedRequest);
        _endWithToast('');
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
      final msg = needCam ? S.of(context).pleaseGrantMicCam : S.of(context).pleaseGrantMic;

      try { await _audioPlayer.stop(); } catch (_) {}
      unawaited(WakelockPlus.disable());
      Fluttertoast.showToast(msg: msg);

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        _backToHome();
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
      ),
    );
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
      if (_status(p) == 2) _endWithToast(S.of(context).callerEndedRequest);
    }));
    _wsUnsubs.add(ws.on('call.invite', (p) {
      if (!_sameChannel(p) || _busy) return;
      if (_status(p) == 2) _endWithToast(S.of(context).callerEndedRequest);
    }));
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 30), () async {
      if (!mounted || _busy) return;
      await _reject(toast: S.of(context).incomingTimeout);
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

    await _closeMiniIfAny();
    _backToHome();
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

    await _closeMiniIfAny();
    _backToHome();
  }

  Future<void> _accept() async {
    if (_busy) return;
    _busy = true;

    if (ref.read(callAbortProvider).contains(widget.channelName)) {
      _endWithToast(S.of(context).callerEndedRequest);
      return;
    }

    _timeoutTimer?.cancel();
    unawaited(_audioPlayer.stop());

    final mePrefVideo = ref.read(userProfileProvider)?.isVideoCall ?? true;
    final wantVideo   = mePrefVideo && (widget.callerFlag == 1);
    final needCam     = wantVideo;

    final req = <Permission>[Permission.microphone, if (needCam) Permission.camera];
    final statuses = await req.request();
    final micOk = statuses[Permission.microphone] == PermissionStatus.granted;
    final camOk = !needCam || statuses[Permission.camera] == PermissionStatus.granted;
    if (!micOk || !camOk) {
      _busy = false;
      final msg = needCam ? S.of(context).pleaseGrantMicCam : S.of(context).pleaseGrantMic;
      Fluttertoast.showToast(msg: msg);
      return;
    }

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
      if (e is ApiException) {
        switch (e.code) {
          case 102: Fluttertoast.showToast(msg: S.of(context).insufficientBalanceTopup); break;
          case 121: Fluttertoast.showToast(msg: S.of(context).calleeBusy); break;
          case 123: Fluttertoast.showToast(msg: S.of(context).calleeOffline); break;
          case 125: Fluttertoast.showToast(msg: S.of(context).calleeDnd); break;
          default:  AppErrorToast.show(e);
        }
      } else {
        AppErrorToast.show(e);
      }
      return null;
    });

    if (token == null) {
      final resp = await acceptFuture;
      if (resp == null) {
        _busy = false;
        return;
      }
      final data = (resp['data'] is Map)
          ? Map<String, dynamic>.from(resp['data'])
          : const <String, dynamic>{};
      token = (data['string'] ?? data['token'])?.toString();
      if (token == null || token.isEmpty) {
        _busy = false;
        Fluttertoast.showToast(msg: S.of(context).acceptFailedMissingToken);
        return;
      }
    } else {
      unawaited(acceptFuture);
    }

    if (!mounted || ref.read(callAbortProvider).contains(widget.channelName)) {
      _endWithToast(S.of(context).callerEndedRequest);
      return;
    }

    if (!mounted) return;
    final me = ref.read(userProfileProvider)!;

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
    final t = S.of(context); // ← 多語言

    // ★ 持續監聽通話是否被中止
    ref.listen<Set<String>>(callAbortProvider, (prev, next) {
      if (next.contains(widget.channelName)) {
        _endWithToast(t.callerEndedRequest);
      }
    });

    return WillPopScope(
      onWillPop: () async {
        _goMini();
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
                      widget.callerFlag == 1 ? t.inviteVideoCall : t.inviteVoiceCall,
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
                          child: SvgPicture.asset(
                            widget.callerFlag == 1 ? 'assets/call_live_accept.svg' : 'assets/call_voice_accept.svg',
                            width: 64, height: 64,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: top + 8,
              left: 8,
              child: IconButton(
                icon: Image.asset('assets/zoom.png', width: 20, height: 20),
                onPressed: _goMini,
                tooltip: t.minimizeScreen,
                splashRadius: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
