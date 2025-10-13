// presence_reporter.dart
import 'dart:async';
import 'package:djs_live_stream/push/push_token_registrar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/widgets.dart';

import '../features/mine/user_repository_provider.dart';
import '../features/profile/profile_controller.dart';
import 'app_lifecycle.dart';

enum PresenceState { fg, bg, ringing, inCall }

class PresenceReporter {
  PresenceReporter._();
  static final PresenceReporter I = PresenceReporter._();

  Timer? _hb;
  Timer? _bgDebounce;
  bool _started = false;
  PresenceState _cur = PresenceState.bg;

  // 為了避免封包亂序，帶遞增序號（後端用 last-write-wins）
  Future<int> _nextSeq() async {
    final sp = await SharedPreferences.getInstance();
    final v = sp.getInt('presence.seq') ?? 0;
    final n = v + 1;
    await sp.setInt('presence.seq', n);
    return n;
    // 也可用時間戳 + 隨機數，這邊簡單遞增即可
  }

  Future<void> start(WidgetRef ref) async {
    if (_started) return;
    _started = true;

    // 先立即報一次（依當下狀態）
    if (AppLifecycle.I.isForeground) {
      await _onForeground(ref, reason: 'app-start');
    } else {
      await _onBackground(ref, reason: 'app-start');
    }

    // 綁到你的全局 AppLifecycle
    AppLifecycle.I.addOnResumed(() => _onForeground(ref, reason: 'resume'));
    AppLifecycle.I.addOnPaused(()  => _onBackgroundDebounced(ref, reason: 'paused'));
    AppLifecycle.I.addOnInactive(() => _onBackgroundDebounced(ref, reason: 'inactive'));
    AppLifecycle.I.addOnDetached(() => _fireAndForget(ref, PresenceState.bg, ttlSec: 15, reason: 'detached'));
  }

  Future<void> stop() async {
    _started = false;
    _hb?.cancel(); _hb = null;
    _bgDebounce?.cancel(); _bgDebounce = null;
  }

  // === 外部可選擇標記的狀態（不影響 UI，只給後端參考） ===
  Future<void> markRinging(WidgetRef ref)  => _fireAndForget(ref, PresenceState.ringing, ttlSec: 60, reason: 'ringing');
  Future<void> markInCall(WidgetRef ref)   => _fireAndForget(ref, PresenceState.inCall, ttlSec: 120, reason: 'in-call');
  Future<void> markCallEnded(WidgetRef ref)=> _fireAndForget(ref, AppLifecycle.I.isForeground ? PresenceState.fg : PresenceState.bg,
      ttlSec: AppLifecycle.I.isForeground ? 40 : 15,
      reason: 'call-ended');

  // === lifecycle handlers ===
  Future<void> _onForeground(WidgetRef ref, {required String reason}) async {
    _bgDebounce?.cancel();
    _startHeartbeat(ref);
    await _send(ref, PresenceState.fg, ttlSec: 40, reason: reason, immediate: true);
  }

  // 背景狀態用「抖動防護」：例如 3~5 秒後才真正上報
  void _onBackgroundDebounced(WidgetRef ref, {required String reason}) {
    _bgDebounce?.cancel();
    _stopHeartbeat();
    _bgDebounce = Timer(const Duration(seconds: 4), () {
      _onBackground(ref, reason: reason);
    });
  }

  Future<void> _onBackground(WidgetRef ref, {required String reason}) async {
    await _send(ref, PresenceState.bg, ttlSec: 15, reason: reason, immediate: true);
  }

  void _startHeartbeat(WidgetRef ref) {
    _hb?.cancel();
    // 前景續約：25s 一次，伺服器 TTL 至少 40s
    _hb = Timer.periodic(const Duration(seconds: 25), (_) {
      _send(ref, PresenceState.fg, ttlSec: 40, reason: 'heartbeat');
    });
  }

  void _stopHeartbeat() { _hb?.cancel(); _hb = null; }

  // === 實際送 API ===
  Future<void> _fireAndForget(WidgetRef ref, PresenceState s, {required int ttlSec, required String reason}) async {
    unawaited(_send(ref, s, ttlSec: ttlSec, reason: reason));
  }

  Future<void> _send(WidgetRef ref, PresenceState s, {required int ttlSec, required String reason, bool immediate = false}) async {
    final user = ref.read(userProfileProvider);
    if (user == null) return;

    // 不要太頻繁地重覆送相同狀態（心跳例外）
    if (!immediate && s == _cur) return;

    try {
      final repo     = ref.read(userRepositoryProvider);
      final seq      = await _nextSeq();
      await repo.setPresence(
        isOnline: s == PresenceState.fg,
      );

      _cur = s;
      debugPrint('[presence] sent state=${_mapState(s)} ttl=$ttlSec reason=$reason seq=$seq');
    } catch (e) {
      // 不拋錯；失敗時交給 TTL 自動過期回落到推播
      debugPrint('[presence] send error: $e (state=${_mapState(s)})');
    }
  }

  String _mapState(PresenceState s) {
    switch (s) {
      case PresenceState.fg: return 'fg';
      case PresenceState.bg: return 'bg';
      case PresenceState.ringing: return 'ringing';
      case PresenceState.inCall: return 'in_call';
    }
  }
}
