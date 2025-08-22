import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ws/ws_provider.dart';
import '../../globals.dart';
import '../live/broadcaster_page.dart';
import '../profile/profile_controller.dart';
import 'incoming_call_page.dart';



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
  DateTime? _lastInviteAt; // 節流一下，避免極端重複

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[CALL-LISTENER] initState');

    final ws = ref.read(wsProvider);
    debugPrint('[CALL-LISTENER] ensureConnected() ...');
    ws.ensureConnected();

    // 🔔 只監聽 call.invite（WsService 已會自動從 call 沒 state 衍生出 call.invite）
    _unsubs.add(ws.on('call.invite', _onInvite));
    debugPrint('[CALL-LISTENER] subscribed "call.invite"');
  }

  void _onInvite(Map<String, dynamic> p) {
    debugPrint('[CALL-LISTENER] _onInvite payload=$p');
    if (_showingIncoming) {
      debugPrint('[CALL-LISTENER] already showing incoming page, skip');
      return;
    }

    final channel   = (p['channel_name'] ?? p['channle_name'] ?? p['data']?['channel_id'])?.toString() ?? '';
    final fromUid   = (p['uid'] as num?)?.toInt();
    final toUid     = (p['to_uid'] as num?)?.toInt();
    final callId    = p['call_id']?.toString();
    final rtcToken  = (p['token'] ?? p['data']?['token'])?.toString();
    final callerName   = p['from_name']?.toString() ?? '來電';
    final callerAvatar = p['from_avatar']?.toString() ?? '';

    debugPrint('[CALL-LISTENER] parsed channel="$channel" fromUid=$fromUid toUid=$toUid callId=$callId tokenLen=${rtcToken?.length}');
    if (channel.isEmpty || fromUid == null || toUid == null || rtcToken == null || rtcToken.isEmpty) {
      debugPrint('[CALL-LISTENER] invite incomplete -> missing channel/from/to/token, ignore');
      return;
    }

    _showingIncoming = true;

    Future.microtask(() async {
      try {
        final route = MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => IncomingCallPage(
            channelName : channel,
            fromUid     : fromUid,
            toUid       : toUid,
            callerName  : callerName,
            callerAvatar: callerAvatar,
            rtcToken    : rtcToken,
            callId      : callId,
          ),
        );

        final nav = rootNavigatorKey.currentState;
        if (nav == null) {
          debugPrint('[CALL-LISTENER] rootNavigatorKey.currentState is NULL, delay to next frame');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final nav2 = rootNavigatorKey.currentState;
            if (nav2 == null) {
              debugPrint('[CALL-LISTENER] still NULL after frame, give up this invite');
              _showingIncoming = false;
              return;
            }
            debugPrint('[CALL-LISTENER] pushing (postFrame) via rootNavigatorKey');
            nav2.push(route);
          });
        } else {
          debugPrint('[CALL-LISTENER] pushing via rootNavigatorKey');
          await nav.push(route);
        }
      } catch (e, st) {
        debugPrint('[CALL-LISTENER] push IncomingCallPage error: $e\n$st');
      } finally {
        _showingIncoming = false;
        debugPrint('[CALL-LISTENER] reset _showingIncoming=false');
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[CALL-LISTENER] lifecycle=$state');
    if (state == AppLifecycleState.resumed) {
      debugPrint('[CALL-LISTENER] resumed -> ensureConnected()');
      ref.read(wsProvider).ensureConnected();
    }
  }

  @override
  void dispose() {
    debugPrint('[CALL-LISTENER] dispose, unsubscribing ${_unsubs.length}');
    WidgetsBinding.instance.removeObserver(this);
    for (final u in _unsubs) { u(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}