
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// 全局可呼叫：把任意 child 以小窗方式插入到 App root overlay。
/// 全局：App 內懸浮視窗（不依賴系統 PiP）
class CallOverlay {
  static OverlayEntry? _entry;

  static bool get isShowing => _entry != null;

  static void show({
    GlobalKey<NavigatorState>? navigatorKey, // ★ 用這個
    required Widget child,
  }) {
    if (_entry != null) {
      debugPrint('[CallOverlay] already showing, skip.');
      return;
    }

    _entry = OverlayEntry(builder: (_) => _MiniCallDraggable(child: child));

    // 1) 優先 navigatorKey
    OverlayState? overlay = navigatorKey?.currentState?.overlay;

    if (overlay == null) {
      debugPrint('[CallOverlay] ❌ No Overlay found. '
          'Provide navigatorKey or rootContext of the root navigator.');
      _entry = null;
      return;
    }

    overlay.insert(_entry!);
    debugPrint('[CallOverlay] ✅ inserted on root overlay');
  }

  static void hide() {
    if (_entry == null) return;
    _entry!.remove();
    _entry = null;
    debugPrint('[CallOverlay] removed');
  }
}


class _MiniCallDraggable extends StatefulWidget {
  const _MiniCallDraggable({required this.child});
  final Widget child;

  @override
  State<_MiniCallDraggable> createState() => _MiniCallDraggableState();
}

class _MiniCallDraggableState extends State<_MiniCallDraggable> {
  Offset pos = const Offset(16, 120);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Draggable(
        feedback: _miniBox(widget.child),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (d) {
          final p = d.offset;
          setState(() {
            const w = 160.0, h = 220.0;
            pos = Offset(
              p.dx.clamp(8, size.width  - w - 8),
              p.dy.clamp(8, size.height - h - 8),
            );
          });
        },
        child: _miniBox(widget.child),
      ),
    );
  }

  Widget _miniBox(Widget child) => Material(
    color: Colors.transparent,
    elevation: 12,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: Container(
      width: 160,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    ),
  );
}
