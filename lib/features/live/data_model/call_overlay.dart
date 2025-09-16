
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


/// 全局可呼叫：把任意 child 以小窗方式插入到 App root overlay。
class CallOverlay {
  static OverlayEntry? _entry;
  static bool get isShowing => _entry != null;

  // Android 通道
  static const MethodChannel _pip = MethodChannel('pip');

  static Future<void> _armPip({required bool enable, Rect? rect}) async {
    if (!Platform.isAndroid) return;
    try {
      final args = <String, dynamic>{
        'enable': enable,
        'w': 9,         // 9:16 比例
        'h': 16,
        if (rect != null) 'left':  rect.left.toInt(),
        if (rect != null) 'top':   rect.top.toInt(),
        if (rect != null) 'width': rect.width.toInt(),
        if (rect != null) 'height':rect.height.toInt(),
      };
      await _pip.invokeMethod('armAutoPip', args);
    } catch (e) {
      debugPrint('[CallOverlay] armAutoPip error: $e');
    }
  }

  /// 提供給子元件（小窗）呼叫，更新 SourceRectHint
  static Future<void> updatePipRect(Rect rect) => _armPip(enable: true, rect: rect);

  static Future<void> show({
    GlobalKey<NavigatorState>? navigatorKey,
    required Widget child,
  }) async {
    if (_entry != null) {
      debugPrint('[CallOverlay] already showing, skip.');
      return;
    }

    // 先建立 overlay
    _entry = OverlayEntry(builder: (_) => _MiniCallDraggable(child: child));

    final overlay = navigatorKey?.currentState?.overlay;
    if (overlay == null) {
      debugPrint('[CallOverlay] ❌ No Overlay found. Provide a root navigatorKey.');
      _entry = null;
      return;
    }

    overlay.insert(_entry!);
    debugPrint('[CallOverlay] ✅ inserted on root overlay');

    // ★ 關鍵：小窗顯示 → 只在這時把 autoPiP 打開（先不帶 rect，稍後由子元件補上）
    await _armPip(enable: true);
  }

  static Future<void> hide() async {
    if (_entry == null) return;
    _entry!.remove();
    _entry = null;
    debugPrint('[CallOverlay] removed');

    // ★ 小窗關閉 → 關閉 autoPiP（之後按 Home/Overview 就不會進系統 PiP）
    await _armPip(enable: false);
  }
}

class _MiniCallDraggable extends StatefulWidget {
  const _MiniCallDraggable({required this.child});
  final Widget child;

  @override
  State<_MiniCallDraggable> createState() => _MiniCallDraggableState();
}

class _MiniCallDraggableState extends State<_MiniCallDraggable> {
  final GlobalKey _boxKey = GlobalKey();
  Offset pos = const Offset(16, 120);

  @override
  void initState() {
    super.initState();
    // 初次插入一幀後回報位置給原生作為 SourceRectHint
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPipRect());
  }

  void _syncPipRect() {
    final renderObj = _boxKey.currentContext?.findRenderObject();
    if (renderObj is RenderBox && renderObj.hasSize) {
      final topLeft = renderObj.localToGlobal(Offset.zero);
      final size = renderObj.size;
      CallOverlay.updatePipRect(
        Rect.fromLTWH(topLeft.dx, topLeft.dy, size.width, size.height),
      );
    }
  }

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
          // 拖曳結束 → 更新 PiP hintRect
          _syncPipRect();
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
      key: _boxKey, // ★ 用來量測位置/尺寸
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
