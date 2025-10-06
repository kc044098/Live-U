// pip_system_ui.dart
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data_model/call_timer.dart';

class PipSystemUi {
  PipSystemUi._();
  static final _ch = const MethodChannel('pip');
  static GlobalKey<NavigatorState>? _navKey;
  static OverlayEntry? _entry;

  static void init({required GlobalKey<NavigatorState> navigatorKey}) {
    _navKey = navigatorKey;
    // 監聽原生回傳的 PiP 狀態
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'prePiP') {
        _show();
      }
      if (call.method == 'pipState') {
        final inPip = call.arguments == true;
        if (inPip) {
          _show();
        } else {
          _hide();
        }
      }
      return;
    });
  }

  static void _show() {
    if (!Platform.isAndroid) return;
    if (_entry != null) return;

    final overlay = _navKey?.currentState?.overlay;
    if (overlay == null) return;

    _entry = OverlayEntry(builder: (_) => const _PipMask());
    overlay.insert(_entry!);
  }

  static void _hide() {
    _entry?.remove();
    _entry = null;
  }
}

// 這個小元件就是白底 + 計時器
class _PipMask extends ConsumerWidget {
  const _PipMask({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(callTimerProvider.select((t) => t.text));

    return IgnorePointer(
      ignoring: true, // PiP 本來不可互動，保險不吃事件
      child: ColoredBox(
        color: Colors.white,
        child: Center(
          child: DefaultTextStyle( // ← 把任何繼承到的裝飾清掉
            style: const TextStyle(
              decoration: TextDecoration.none,
              decorationColor: Colors.transparent,
              decorationThickness: 0.0,
              // 指定基礎字重/大小讓渲染穩定
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: Colors.black,
              height: 1.0, // 緊貼基線，避免額外上下間距引出奇怪裝飾
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              // 避免不必要的首/尾行高度調整
              textHeightBehavior: const TextHeightBehavior(
                applyHeightToFirstAscent: false,
                applyHeightToLastDescent: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}