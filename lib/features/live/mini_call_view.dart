import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../call/rtc_engine_manager.dart';
import 'data_model/call_overlay.dart';
import 'data_model/call_timer.dart';

class MiniCallView extends ConsumerStatefulWidget {
  final BuildContext rootContext;
  final String roomId;
  final bool isVoice;
  final int? remoteUid;
  final VoidCallback onExpand;

  const MiniCallView({
    super.key,
    required this.rootContext,
    required this.roomId,
    required this.isVoice,
    required this.remoteUid,
    required this.onExpand,
  });

  @override
  ConsumerState<MiniCallView> createState() => _MiniCallViewState();
}

class _MiniCallViewState extends ConsumerState<MiniCallView> {
  late final RtcEngineManager _rtc;

  @override
  void initState() {
    super.initState();
    _rtc = RtcEngineManager();

    // ✅ 進入小窗時，保險把音訊打開 + 走外放（這些都是冪等設定，重複呼叫無害）
    final eng = _rtc.engine;
    if (eng != null) {
      // 這些 API 名稱請依你使用的 agora_rtc_engine 版本調整（6.x 皆可）
      eng.enableAudio();
      eng.muteAllRemoteAudioStreams(false);
      eng.setDefaultAudioRouteToSpeakerphone(true);
      eng.setEnableSpeakerphone(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timerText = ref.watch(callTimerProvider.select((t) => t.text));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () async {
        debugPrint('[MiniCallView] expand requested');
        CallOverlay.hide();
        widget.onExpand();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.white,
          child: Center(
            child: Text(
              timerText,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
