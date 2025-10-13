// lib/push/push_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/error_handler.dart';
import '../features/call/call_repository.dart';
import 'app_lifecycle.dart';
import 'banner_service.dart';
import 'nav_helpers.dart';

// === 背景 isolate 入口：收到 FCM 時呼叫 ===
@pragma('vm:entry-point')
Future<void> firebaseBgHandler(RemoteMessage message) async {
  // 背景 isolate 需手動初始化
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  DartPluginRegistrant.ensureInitialized();

  debugPrint('[FCM][BG] id=${message.messageId} data=${message.data}');

  final svc = PushService._bg();
  await svc._ensureInitializedLocalPlugin(forBg: true);
  await svc._showFromRemoteMessage(message, fromBg: true);
}

// 點擊通知的「背景回呼」（App 被殺時點擊 action）
const _kPendingAction = 'pending_call_action';
@pragma('vm:entry-point')
void onTapNotificationBg(NotificationResponse details) async {
  WidgetsFlutterBinding.ensureInitialized();
  final sp = await SharedPreferences.getInstance();
  final payload = details.payload ?? '{}';
  final action = details.actionId ?? '';
  debugPrint('[[FCM][BG-TAP]] action=$action payload=$payload'); // ★

  try {
    final data = jsonDecode(payload) as Map<String, dynamic>;
    await sp.setString(_kPendingAction, jsonEncode({...data, '__action__': action}));
  } catch (e, st) {
    debugPrint('[[FCM][BG-TAP]] decode error: $e\n$st');
  }
}


class PushService {
  PushService._();
  PushService._bg(); // 給背景 isolate 用
  static final PushService I = PushService._();

  final _fln = FlutterLocalNotificationsPlugin();

  static const _kPendingIncoming = 'pending_incoming_call';

  // 渠道
  static const _chMsgsId  = 'messages';
  static const _chCallsId = 'calls_v2';

  StreamSubscription<RemoteMessage>? _fgSub;

  Future<void> init() async {
    // 1) 允許通知（Android 13+ 會跳系統權限）
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    // 2) 初始化本地通知 + 建立渠道
    await _ensureInitializedLocalPlugin();

    _fgSub = FirebaseMessaging.onMessage.listen((m) {
      // ✅ 前景也進統一路徑
      _showFromRemoteMessage(m, fromBg: false);
    });

    // 3) 使用者點擊通知進 App
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleTapPayload(m.data));

    // 4) 使用者從「完全關掉」狀態點通知進來
    final initial = await fcm.getInitialMessage();
    if (initial != null) _handleTapPayload(initial.data);

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false, badge: false, sound: false,
    );

    await _drainPendingActions();
  }

  Future<void> _ensureInitializedLocalPlugin({bool forBg = false}) async {
    // Android
    const initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS（Darwin）
    final darwinInit = DarwinInitializationSettings(
      requestAlertPermission: !forBg,
      requestBadgePermission: !forBg,
      requestSoundPermission: !forBg,
      notificationCategories: [
        DarwinNotificationCategory(
          'incoming_call',
          actions: [
            DarwinNotificationAction.plain(
              'ACCEPT', 'ACCEPT',
              options: const {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              'REJECT', 'REJECT',
              options: {DarwinNotificationActionOption.destructive},
            ),
          ],
          options: const {DarwinNotificationCategoryOption.customDismissAction},
        ),
      ],
    );


    await _fln.initialize(
      InitializationSettings(android: initAndroid, iOS: darwinInit),
      onDidReceiveNotificationResponse: (resp) {
        if (resp.payload != null) _handleTapPayload(jsonDecode(resp.payload!));
        final action = resp.actionId;
        if (action == 'ACCEPT' || action == 'REJECT') {
          final payload = resp.payload != null ? jsonDecode(resp.payload!) : {};
          payload['__action__'] = action;
          _handleTapPayload(payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: onTapNotificationBg,
    );

    // Android 才需要建立 Channel；iOS 不用
    final android = _fln.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    // calls_v2：帶自訂鈴聲 ringtone.wav（放在 res/raw）
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _chCallsId,
      'Incoming Calls',
      description: 'Call notifications',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('ringtone'), // ← 不要副檔名
      playSound: true,
    ));

    await android?.createNotificationChannel(const AndroidNotificationChannel(
      _chMsgsId, 'Messages',
      description: 'Message notifications',
      importance: Importance.high,
    ));
  }

  Future<void> _showFromRemoteMessage(RemoteMessage m, {bool fromBg = false}) async {
    debugPrint('[FCM][handle] id=${m.messageId} fromBg=$fromBg data=${m.data}');

    // ✅ 不再因為前景而整體早退，改用型別分流（call 一律顯示）

    final data = normalize(m);

    // ---- 小工具 ----
    String s(dynamic v) => v?.toString() ?? '';
    int? i(dynamic v) => (v is num) ? v.toInt() : int.tryParse(s(v));

    bool _isChat(Map<String, dynamic> d) {
      final kind = s(d['kind']).toLowerCase();
      final type = s(d['type']).toLowerCase();
      return kind == 'chat' || kind == 'room_chat' || type == '8';
    }

    // 將 status 或 event 映射成 call 事件；回傳 '' 代表不是 call
    String _callEvent(Map<String, dynamic> d) {
      final kind = s(d['kind']).toLowerCase();
      final type = s(d['type']).toLowerCase();
      final hasCallMarker = kind.startsWith('call') || type == '6' || type == 'call';
      if (!hasCallMarker) return '';

      String ev = s(d['event']).toLowerCase();
      if (ev.isEmpty) ev = s(d['call_event']).toLowerCase();

      // 後端若用數字或其他字串放在 status
      final statusRaw = d['status'] ?? (d['data'] is Map ? (d['data']['status']) : null);
      final st = s(statusRaw).toLowerCase();

      if (ev.isNotEmpty) return ev;

      // 無 event -> 由 status 推斷
      switch (st) {
        case '0':
        case 'invite':
        case 'ringing':
          return 'invite';
        case '1':
        case 'accept':
        case 'accepted':
          return 'accept';
        case '2':
        case 'reject':
          return 'reject';
        case 'cancel':
          return 'cancel';
        case 'timeout':
          return 'timeout';
        case 'end':
        case 'hangup':
          return 'end';
        case 'busy':
          return 'busy';
      }

      // 既沒有 event 也沒 status，就把它當 invite（最保守）
      return 'invite';
    }

    // ---- 先處理「call 系列」 ----
    final ev = _callEvent(data);
    if (ev.isNotEmpty) {
      // 終止性/校正性事件：直接收掉本地 UI/通知
      if (ev != 'invite') {
        try { final nid = data['__nid__'] as int?; if (nid != null) _fln.cancel(nid); } catch (_) {}
        BannerService.I.dismiss();

        if (ev == 'accept') { goToLiveFromPayload(data); }
        return;
      }

      // 邀請事件（來電）
      final name = s(data['nick_name']).isNotEmpty ? s(data['nick_name']) : 'Incoming call';
      final flag = i(data['flag']) ?? 1; // 1=video, 2=voice
      final timeoutSec = i(data['timeout']) ?? 30;

      await _showIncomingCall(
        title: name,
        body: (flag == 2) ? 'Voice call' : 'Video call',
        payload: data,
        timeoutSec: timeoutSec,
      );
      return;
    }

    // ---- 再處理「聊天」 ----
    if (_isChat(data)) {
      final title = s(data['nick_name']).isNotEmpty
          ? s(data['nick_name'])
          : (s(data['title']).isNotEmpty ? s(data['title']) : 'New message');
      final preview = _resolveChatPreview(data);

      await _showMessage(title: title, body: preview, payload: data);
      return;
    }

    // 其他型別：暫不處理
    debugPrint('[FCM] ignored payload (kind=${s(data['kind'])}, type=${s(data['type'])})');
  }

  Future<void> _showIncomingCall({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
    int timeoutSec = 30,
  }) async {
    final id = _randomId();

    // 1) 把這通來電先寫到本機，供 full-screen 把 App 拉到前景後顯示你的 Banner
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kPendingIncoming, jsonEncode({...payload, '__nid__': id}));

    // 2) Android：full-screen 來電通知
    final android = AndroidNotificationDetails(
      _chCallsId, 'Incoming Calls',
      channelDescription: 'Call notifications',
      category: AndroidNotificationCategory.call,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,         // ← 關鍵
      ongoing: true,
      autoCancel: false,
      ticker: 'Incoming call',        // 一些裝置會顯示狀態列提示
      timeoutAfter: timeoutSec * 1000,
      // 動作鈕（可選；點了會觸發 onDidReceiveNotificationResponse）
      actions: const [
        AndroidNotificationAction('ACCEPT', 'ACCEPT', showsUserInterface: true, cancelNotification: true),
        AndroidNotificationAction('REJECT', 'REJECT', showsUserInterface: true, cancelNotification: true),
      ],
    );

    const ios = DarwinNotificationDetails(
      categoryIdentifier: 'incoming_call',
      interruptionLevel: InterruptionLevel.timeSensitive,
      presentAlert: true,
      presentSound: true,
      sound: 'ringtone.wav', // iOS 你也要有這檔，或改 'default'
      threadIdentifier: 'calls',
    );

    await _fln.show(
      id,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
      payload: jsonEncode({...payload, '__kind__': 'call', '__nid__': id}),
    );
  }

  Future<void> _showMessage({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    final id = _randomId();

    final android = AndroidNotificationDetails(
      _chMsgsId, 'Messages',
      channelDescription: 'Message notifications',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    );

    // iOS 前景也要顯示
    const ios = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.active,
      presentAlert: true,
      presentSound: true,
      threadIdentifier: 'messages',
    );

    await _fln.show(
      id,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
      payload: jsonEncode({...payload, '__kind__': 'chat', '__nid__': id}),
    );
  }

  Future<void> maybeShowPendingIncomingUI() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kPendingIncoming);
    if (raw == null || raw.isEmpty) return;

    final data = jsonDecode(raw) as Map<String, dynamic>;
    final nid = data['__nid__'] as int?;

    if (nid != null) {
      await _fln.cancel(nid);
      debugPrint('[CALL][ui] canceled incoming notification nid=$nid (no banner)');
    }

    // 只清掉，不顯示任何 UI
    await sp.remove(_kPendingIncoming);
  }

  void _handleTapPayload(Map<String, dynamic> data) {

    final kind   = (data['__kind__'] ?? data['kind'] ?? '').toString();
    final action = (data['__action__'] ?? '').toString();
    debugPrint('[[PUSH][TAP]] kind=$kind action=$action data=$data'); // ★
    if (kind.startsWith('call')) {
      final nid = data['__nid__'] as int?;

      if (action == 'ACCEPT') {
        if (nid != null) _fln.cancel(nid);
        _acceptFromNotification(data);   // ★ 新增：完整接聽流程
        return;
      }

      if (action == 'REJECT') {
        if (nid != null) _fln.cancel(nid);
        _rejectFromNotification(data);   // ★ 新增：回報拒接
        return;
      }
      if (nid != null) _fln.cancel(nid);
      return;
    }

    if (kind == 'chat' || kind == 'room_chat') {
      openChatFromPayload(data);
      return;
    }
  }

  Future<void> _rejectFromNotification(Map<String, dynamic> data) async {
    try {
      final ch = (data['channel_id'] ?? data['roomId'] ?? '').toString();
      if (ch.isEmpty) return;
      final container = provider_container;
      if (container == null) return;
      await container.read(callRepositoryProvider).respondCall(
        channelName: ch,
        callId: null,
        accept: false,
      );
    } catch (_) {}
  }

  Future<void> _acceptFromNotification(Map<String, dynamic> data) async {
    debugPrint('[[CALL][ACCEPT]] begin data=$data');
    final container = provider_container;
    if (container == null) return;

    final needCam = (int.tryParse('${data['flag'] ?? 1}') ?? 1) == 1;
    final req = <Permission>[Permission.microphone, if (needCam) Permission.camera];
    final statuses = await req.request();
    final micOk = statuses[Permission.microphone] == PermissionStatus.granted;
    final camOk = !needCam || statuses[Permission.camera] == PermissionStatus.granted;
    debugPrint('[[CALL][ACCEPT]] perms mic=$micOk cam=$camOk needCam=$needCam');
    if (!micOk || !camOk) {
      Fluttertoast.showToast(msg: needCam ? 'Mic and camera permissions required' : 'Microphone permission required');
      return;
    }

    String? token = (data['token'] ?? data['agora_token'])?.toString();
    final ch = (data['channel_id'] ?? data['roomId'] ?? '').toString();
    if (ch.isEmpty) { debugPrint('[[CALL][ACCEPT]] empty channel'); return; }

    if (token == null || token.isEmpty) {
      // 這是「阻斷路徑」：需要靠 API 取得 token，失敗才要提示
      final d = await _respondAccept(container, ch, timeout: const Duration(seconds: 6), surfaceError: true);
      token = d?['string']?.toString() ?? d?['token']?.toString();
      debugPrint('[[CALL][ACCEPT]] gotToken=${token != null && token!.isNotEmpty}');
      if (token == null || token.isEmpty) {
        Fluttertoast.showToast(msg: 'Failed to accept');
        return;
      }
    } else {
      // 已有 token：後端只需校正狀態 → 背景靜默送，不要冒泡錯誤
      unawaited(_respondAccept(container, ch, timeout: const Duration(seconds: 3), surfaceError: false));
    }

    final jump = {...data, 'token': token};
    debugPrint('[[CALL][ACCEPT]] goToLive room=${jump['channel_id'] ?? jump['roomId']}');
    goToLiveFromPayload(jump);
  }

  Future<Map<String, dynamic>?> _respondAccept(
      ProviderContainer container,
      String ch, {
        Duration timeout = const Duration(seconds: 5),
        bool surfaceError = false, // 只在需要 token 的阻斷路徑才 true
      }) async {
    try {
      final resp = await container
          .read(callRepositoryProvider)
          .respondCall(channelName: ch, callId: null, accept: true)
          .timeout(timeout);
      debugPrint('[[CALL][ACCEPT]] respondCall resp=$resp');
      if (resp is Map && resp['data'] is Map) {
        return Map<String, dynamic>.from(resp['data']);
      }
    } on TimeoutException catch (e, st) {
      debugPrint('[[CALL][ACCEPT]] respondCall timeout: $e\n$st');
      if (surfaceError) AppErrorToast.show('[CALL] respondCall timeout');
    } catch (e, st) {
      debugPrint('[[CALL][ACCEPT]] respondCall error: $e\n$st');
      if (surfaceError) AppErrorToast.show(e);
    }
    return null;
  }

  // 依你 WS 結構，把 preview 轉成一行文字
  String _resolveChatPreview(Map<String, dynamic> data) {
    final content = (data['content'] ?? '').toString();
    try {
      final outer = jsonDecode(content);
      if (outer is Map) {
        final txt = (outer['chat_text'] ?? '').toString();
        final img = (outer['img_path'] ?? outer['image_path'] ?? '').toString();
        final voice = (outer['voice_path'] ?? '').toString();
        if (img.isNotEmpty)  return '[Image]';
        if (voice.isNotEmpty) return '[Voice]';
        if (txt.isNotEmpty)  return txt;
      }
    } catch (_) {}
    return content.isNotEmpty ? content : 'New Messages';
  }

  Future<void> _drainPendingActions() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kPendingAction);
    if (raw == null || raw.isEmpty) return;
    await sp.remove(_kPendingAction);
    debugPrint('[[FCM][DRAIN]] $raw'); // ★

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _handleTapPayload(data);
    } catch (e, st) {
      debugPrint('[[FCM][DRAIN]] parse error: $e\n$st');
    }
  }


  Future<void> cancelIncomingCallNotificationIfAny() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final raw = sp.getString(_kPendingIncoming);
      if (raw == null || raw.isEmpty) return;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final nid = data['__nid__'] as int?;
      if (nid != null) {
        await _fln.cancel(nid);
        debugPrint('[CALL][resume] canceled incoming notification nid=$nid');
      } else {
        debugPrint('[CALL][resume] pending payload has no __nid__');
      }
    } catch (e, st) {
      debugPrint('[CALL][resume] cancelIncomingCallNotificationIfAny error: $e\n$st');
    }
  }

  int _randomId() => Random().nextInt(0x7fffffff);
}
