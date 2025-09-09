// edit_profile_fullscreen_video_player_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/member_video_model.dart';
import '../../routes/app_routes.dart';
import '../live/video_repository_provider.dart';
import '../profile/profile_controller.dart';

import 'dart:io';

import 'auto_grow_text_field.dart';

class FullscreenVideoPlayerPage extends ConsumerStatefulWidget {
  final MemberVideoModel item;

  const FullscreenVideoPlayerPage({super.key, required this.item});

  @override
  ConsumerState<FullscreenVideoPlayerPage> createState() =>
      _FullscreenVideoPlayerPageState();
}

class _FullscreenVideoPlayerPageState
    extends ConsumerState<FullscreenVideoPlayerPage>
    with RouteAware, WidgetsBindingObserver { // ⬅ 加入 WidgetsBindingObserver
  late VideoPlayerController _controller;

  // 與圖片頁一致：標題 + 分類（精選/日常） + 樂觀上傳
  late String _selectedCategory;
  final TextEditingController _textController = TextEditingController();
  late final String _origTitle;
  late final int _origIsTop;
  bool _isBroadcaster = false;

  // ===== 新增：Spinner 與續播輔助 =====
  bool _showSpinner = false;
  void _videoValueListener() {
    final v = _controller.value;
    final need = !v.isInitialized || (v.isPlaying && v.isBuffering);
    if (mounted && need != _showSpinner) {
      setState(() => _showSpinner = need);
    }
  }
  void _resumeVideo() {
    _videoValueListener(); // 先校正一次 spinner
    if (!_controller.value.isInitialized) {
      _controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
    } else {
      // 某些機型恢復後需要延一個 microtask 才能正確播放
      Future.microtask(() => _controller.play());
    }
  }
  // ==================================

  String _isTopToCategory(int isTop) => isTop == 1 ? '精選' : '日常';
  int _categoryToIsTop(String cat) => cat == '精選' ? 1 : 2;
  static const int _kMaxTitleLen = 300;

  bool get _hasChanges {
    final t = _textController.text.trim();
    final isTop = _categoryToIsTop(_selectedCategory);
    return (t != _origTitle) || (isTop != _origIsTop);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // ⬅ 監聽前/後景

    // 初始化 UI 狀態
    _selectedCategory = _isTopToCategory(widget.item.isTop);
    _textController.text = widget.item.title;
    _origTitle = widget.item.title;
    _origIsTop = widget.item.isTop;

    _initController();
  }

  Future<void> _initController() async {
    final p = widget.item.videoUrl;
    if (p.startsWith('http')) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(p));
    } else if (p.startsWith('file://') || File(p).existsSync()) {
      _controller = VideoPlayerController.file(
          File(p.startsWith('file://') ? Uri.parse(p).toFilePath() : p));
    } else {
      _controller = VideoPlayerController.asset(p);
    }

    _controller.addListener(_videoValueListener); // ⬅ 監聽 value 變化

    await _controller.initialize();
    await _controller.setLooping(true);
    await _controller.play();
    if (mounted) setState(() {});

    // 初始化後立刻校正一次 spinner 狀態
    WidgetsBinding.instance.addPostFrameCallback((_) => _videoValueListener());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route); // ⬅ RouteAware
  }

  // ====== RouteAware：被其它頁蓋住/返回本頁 ======
  @override
  void didPushNext() {
    if (_controller.value.isInitialized) {
      _controller.pause();
    }
  }

  @override
  void didPopNext() {
    _resumeVideo();
  }
  // =====================================

  // ====== App lifecycle：切到背景/回前景 ======
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _controller.pause();
        break;
      case AppLifecycleState.resumed:
        WidgetsBinding.instance.addPostFrameCallback((_) => _resumeVideo());
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }
  // =====================================

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this); // ⬅ 移除 observer
    _controller.removeListener(_videoValueListener); // ⬅ 移除 listener
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  // 與圖片頁相同的樂觀上傳
  void _saveChangesOptimistically() {
    if (!_hasChanges) {
      Navigator.pop(context, {'updated': false});
      return;
    }

    final id = widget.item.id;
    final raw = _textController.text.trim();
    final title = raw.length > _kMaxTitleLen
        ? raw.substring(0, _kMaxTitleLen)
        : raw;
    final isTop = _categoryToIsTop(_selectedCategory);

    Navigator.pop(context, {
      'updated': true,
      'id': id,
      'title': title,
      'isTop': isTop,
    });

    final repo = ref.read(videoRepositoryProvider);
    // ignore: discarded_futures
    repo.updateVideo(id: id, title: title, isTop: isTop).catchError((e, _) {
      debugPrint('videoUpdate failed: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    _isBroadcaster = user?.isBroadcaster == true;

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          _saveChangesOptimistically();
          return false;
        }
        Navigator.pop(context, {'updated': false});
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_hasChanges) {
                _saveChangesOptimistically();
              } else {
                Navigator.pop(context, {'updated': false});
              }
            },
          ),
        ),
        body: Stack(
          children: [
            // 全螢幕影片
            if (_controller.value.isInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),

            // 🔽 緩衝/讀取時的轉圈圈覆蓋層（與另一頁一致）
            IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: _showSpinner ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),

            // 左下角資訊 + 編輯區
            Positioned(
              left: 16,
              right: 16,
              bottom: 50,
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 24, backgroundImage: user?.avatarImage),
                      const SizedBox(width: 8),
                      if (user != null)
                        Row(
                          children: [
                            Text(user.displayName ?? '',
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            if (user.isVip)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFA770), Color(0xFFD247FE)],
                                  ),
                                ),
                                child: const Text(
                                  'VIP',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AutoGrowTextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        minChars: 10,
                        maxFraction: 0.65,
                        inputFormatters: [LengthLimitingTextInputFormatter(_kMaxTitleLen)],
                        maxLength: _kMaxTitleLen,
                      ),
                      if (_isBroadcaster) ...[
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedCategory == '精選'
                                ? const Color(0xFFFF4D67)
                                : const Color(0xFF3A9EFF),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                          ),
                          onPressed: () => _showCategoryBottomSheet(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_selectedCategory,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('選擇分類',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                title: Text('精選',
                    style: TextStyle(
                        color: _selectedCategory == '精選'
                            ? const Color(0xFFFF4D67)
                            : Colors.black)),
                onTap: () {
                  setState(() => _selectedCategory = '精選');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('日常',
                    style: TextStyle(
                        color: _selectedCategory == '日常'
                            ? const Color(0xFF3A9EFF)
                            : Colors.black)),
                onTap: () {
                  setState(() => _selectedCategory = '日常');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
