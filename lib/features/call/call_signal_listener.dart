import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ws/ws_provider.dart';
import '../../globals.dart';
import '../profile/profile_controller.dart';
import 'incoming_call_page.dart';
import 'dart:async';

class CallSignalListener extends ConsumerStatefulWidget {
  final Widget child;
  const CallSignalListener({super.key, required this.child});

  @override
  ConsumerState<CallSignalListener> createState() => _CallSignalListenerState();
}

class _CallSignalListenerState extends ConsumerState<CallSignalListener>
    with WidgetsBindingObserver {
  final List<VoidCallback> _unsubs = [];
  bool _showingIncoming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final ws = ref.read(wsProvider);
    ws.ensureConnected();

    // 只看新版：來電響鈴 -> call.invite（status=0 或缺省）
    _unsubs.add(ws.on('call.invite', _onInvite));
  }

  Map<String, dynamic> _dataOf(Map p) =>
      (p['data'] is Map) ? Map<String, dynamic>.from(p['data']) : const {};

  int? _asInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse(v?.toString() ?? '');

  String _channel(Map p) => _dataOf(p)['channel_id']?.toString() ?? '';
  String _token(Map p) => (_dataOf(p)['string'] ?? _dataOf(p)['token'])?.toString() ?? '';
  int? _status(Map p) => _asInt(_dataOf(p)['status']); // 0/缺省=響鈴, 1=接通, 2=拒絕
  int? _peerUid(Map p) => _asInt(_dataOf(p)['uid']);
  String _nick(Map p) => _dataOf(p)['nick_name']?.toString() ?? '來電';
  dynamic _avatarRaw(Map p) => _dataOf(p)['avatar'];
  int _flag(Map p) {
    final d = _dataOf(p);
    final v = d.containsKey('flag') ? d['flag'] : d['Flag']; // 兼容大小寫
    if (v == null) return 1;                   // 預設視訊
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 1;
  }

  String? _firstAvatarPath(dynamic v) {
    if (v == null) return null;
    if (v is List && v.isNotEmpty) {
      final s = v.first?.toString().trim();
      return (s?.isNotEmpty ?? false) ? s : null;
    }
    final s = v.toString().trim();
    return s.isNotEmpty ? s : null;
  }

  String _joinCdn(String cdn, String path) {
    if (path.startsWith('http')) return path;
    final a = cdn.endsWith('/') ? cdn.substring(0, cdn.length - 1) : cdn;
    final b = path.startsWith('/') ? path.substring(1) : path;
    return '$a/$b';
  }

  void _onInvite(Map<String, dynamic> p) {
    final st = _status(p) ?? 0;
    if (st != 0) return;

    if (_showingIncoming) return;

    final ch = _channel(p);
    final peerUid = _peerUid(p);           // ← 對方 uid（來自 data.uid）
    if (ch.isEmpty || peerUid == null) return;

    final meUid = ref.read(userProfileProvider)?.uid; // ← 自己 uid（很重要）
    if (meUid == null) return;

    final name = _nick(p);
    final cdn  = ref.read(userProfileProvider)?.cdnUrl ?? '';
    final avatarPath = _firstAvatarPath(_avatarRaw(p));
    final avatarUrl  = (avatarPath == null) ? '' : _joinCdn(cdn, avatarPath);
    final token = _token(p); // 被叫 token（可能有值，若空就代表先別更新）
    final int flag = _flag(p);

    _showingIncoming = true;
    Future.microtask(() async {
      try {
        final route = MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => IncomingCallPage(
            channelName : ch,
            fromUid     : peerUid,  // 對方
            toUid       : int.parse(meUid),    // 自己
            callerName  : name,
            callerAvatar: avatarUrl,
            rtcToken    : token,  // 可能為空 → 進頁後再按接受去拿
            callId      : null,
            callerFlag  : flag,
          ),
        );
        await rootNavigatorKey.currentState!.push(route);
      } finally {
        _showingIncoming = false;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(wsProvider).ensureConnected();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final u in _unsubs) { try { u(); } catch (_) {} }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
