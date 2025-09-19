// video_panes.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/scheduler.dart';

/// 穩定的遠端視訊 Pane：remoteUid 變更時才重建 controller
class StableRemoteVideoView extends StatefulWidget {
  final RtcEngine? engine;
  final String roomId;
  final int? remoteUid;
  final bool remoteVideoOn;    // 用來決定是否顯示頭像覆蓋，不移除視圖
  final ImageProvider avatar;

  const StableRemoteVideoView({
    super.key,
    required this.engine,
    required this.roomId,
    required this.remoteUid,
    required this.remoteVideoOn,
    required this.avatar,
  });

  @override
  State<StableRemoteVideoView> createState() => _StableRemoteVideoViewState();
}

class _StableRemoteVideoViewState extends State<StableRemoteVideoView>
    with AutomaticKeepAliveClientMixin {
  VideoViewController? _controller;
  int? _boundUid;

  @override
  bool get wantKeepAlive => true;

  void _ensureController() {
    if (widget.engine == null || widget.remoteUid == null) {
      _controller = null;
      _boundUid = null;
      return;
    }
    if (_controller != null && _boundUid == widget.remoteUid) return;

    // 只有在遠端 uid 改變時才新建一次 controller
    _controller = VideoViewController.remote(
      rtcEngine: widget.engine!,
      canvas: VideoCanvas(uid: widget.remoteUid),
      connection: RtcConnection(channelId: widget.roomId),
      useFlutterTexture: !(defaultTargetPlatform == TargetPlatform.iOS),
      useAndroidSurfaceView: false,
    );
    _boundUid = widget.remoteUid;
  }

  @override
  void initState() {
    super.initState();
    _ensureController();
  }

  @override
  void didUpdateWidget(covariant StableRemoteVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine != widget.engine || oldWidget.remoteUid != widget.remoteUid) {
      _ensureController();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.engine == null) {
      return const ColoredBox(color: Colors.black);
    }
    if (_controller == null) {
      // 尚未有遠端 uid
      return const ColoredBox(color: Colors.black);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 遠端視訊：保持常駐，不因父層 setState 重建
        const ColoredBox(color: Colors.black), // 保險底色
        RepaintBoundary(child: AgoraVideoView(controller: _controller!)),

        // 遠端關鏡頭的覆蓋（不卸載 AgoraVideoView）
        if (!widget.remoteVideoOn)
          Container(
            color: Colors.black,
            child: Center(child: CircleAvatar(radius: 60, backgroundImage: widget.avatar)),
          ),
      ],
    );
  }
}

/// 穩定的本地預覽 Pane：只在鏡像方向變更時重建 controller
class StableLocalPreviewView extends StatefulWidget {
  final RtcEngine? engine;

  /// 前鏡頭時是否鏡像（你頁面的 _frontCamera）
  final bool mirrorFront;

  /// 是否顯示預覽（你頁面的 _videoOn）
  final bool show;

  /// 是否由元件幫你呼叫 enableLocalVideo/muteLocalVideoStream/startPreview/stopPreview。
  /// 若你已在父層的 _toggleVideo 自己處理，就設 false。
  final bool manageLifecycle;

  const StableLocalPreviewView({
    super.key,
    required this.engine,
    required this.mirrorFront,
    required this.show,
    this.manageLifecycle = true,
  });

  @override
  State<StableLocalPreviewView> createState() => _StableLocalPreviewViewState();
}

class _StableLocalPreviewViewState extends State<StableLocalPreviewView>
    with AutomaticKeepAliveClientMixin {
  VideoViewController? _controller;
  bool? _mirrorFrontBound;
  bool _previewOn = false; // 只在 manageLifecycle=true 時使用

  @override
  bool get wantKeepAlive => true;

  void _ensureController() {
    final engine = widget.engine;
    if (engine == null) {
      _disposeController();
      return;
    }

    // 僅在「鏡像設定變了」時才重建 controller
    if (_controller != null && _mirrorFrontBound == widget.mirrorFront) return;

    _disposeController();

    _controller = VideoViewController(
      rtcEngine: engine,
      canvas: VideoCanvas(
        uid: 0,
        mirrorMode: widget.mirrorFront
            ? VideoMirrorModeType.videoMirrorModeEnabled
            : VideoMirrorModeType.videoMirrorModeDisabled,
      ),
      useFlutterTexture: !(defaultTargetPlatform == TargetPlatform.iOS),
      useAndroidSurfaceView: false,
    );
    _mirrorFrontBound = widget.mirrorFront;
  }

  Future<void> _applyPreviewLifecycle() async {
    if (!widget.manageLifecycle) return;
    final engine = widget.engine;
    if (engine == null) return;

    // 只在狀態有變化時呼叫 Agora API，避免重複呼叫造成 iOS 閃爍
    if (widget.show && !_previewOn) {
      try {
        await engine.enableLocalVideo(true);
        await engine.muteLocalVideoStream(false);
        await engine.startPreview();
        _previewOn = true;
      } catch (_) {}
    } else if (!widget.show && _previewOn) {
      try {
        await engine.muteLocalVideoStream(true);
        await engine.stopPreview();
        await engine.enableLocalVideo(false);
        _previewOn = false;
      } catch (_) {}
    }
  }

  void _disposeController() {
    _controller = null;
    _mirrorFrontBound = null;
  }

  @override
  void initState() {
    super.initState();
    _ensureController();
    // 初始根據 show 決定是否開啟預覽
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyPreviewLifecycle());
  }

  @override
  void didUpdateWidget(covariant StableLocalPreviewView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 引擎替換或鏡像切換 → 檢查 controller
    if (oldWidget.engine != widget.engine ||
        oldWidget.mirrorFront != widget.mirrorFront) {
      _ensureController();
    }

    // 顯示狀態變化 → 應用預覽生命週期
    if (oldWidget.show != widget.show ||
        oldWidget.engine != widget.engine ||
        oldWidget.manageLifecycle != widget.manageLifecycle) {
      _applyPreviewLifecycle();
    }
  }

  @override
  void dispose() {
    // 收尾：如果是由元件管理，就幫忙停預覽
    if (widget.manageLifecycle && _previewOn) {
      final engine = widget.engine;
      if (engine != null) {
        try {
          engine.muteLocalVideoStream(true);
          engine.stopPreview();
          engine.enableLocalVideo(false);
        } catch (_) {}
      }
    }
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.engine == null || _controller == null) {
      return const SizedBox.shrink();
    }

    // 用 Offstage 隱藏，不要用 AnimatedOpacity（iOS 對 texture 合成敏感）
    return Offstage(
      offstage: !widget.show,
      child: RepaintBoundary(
        child: AgoraVideoView(controller: _controller!),
      ),
    );
  }
}