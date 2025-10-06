// edit_profile_fullscreen_video_player_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/member_video_model.dart';
import '../../l10n/l10n.dart';
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
    with RouteAware, WidgetsBindingObserver {
  late VideoPlayerController _controller;

  // 與圖片頁一致：標題 + 分類（多語）
  late String _selectedCategory;
  final TextEditingController _textController = TextEditingController();
  late final String _origTitle;
  late final int _origIsTop;
  bool _isBroadcaster = false;

  bool _showSpinner = false;
  void _videoValueListener() {
    final v = _controller.value;
    final need = !v.isInitialized || (v.isPlaying && v.isBuffering);
    if (mounted && need != _showSpinner) {
      setState(() => _showSpinner = need);
    }
  }
  void _resumeVideo() {
    _videoValueListener();
    if (!_controller.value.isInitialized) {
      _controller.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.setLooping(true);
        _controller.play();
      });
    } else {
      Future.microtask(() => _controller.play());
    }
  }

  // ===== 多語：分類 ↔ isTop 對應 =====
  String _isTopToCategory(BuildContext context, int isTop) {
    final l = S.of(context);
    return isTop == 1 ? l.categoryFeatured : l.categoryDaily;
  }
  int _categoryToIsTop(BuildContext context, String cat) {
    final l = S.of(context);
    return cat == l.categoryFeatured ? 1 : 2;
  }
  static const int _kMaxTitleLen = 300;

  bool get _hasChanges {
    final t = _textController.text.trim();
    final isTop = _categoryToIsTop(context, _selectedCategory);
    return (t != _origTitle) || (isTop != _origIsTop);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 初始化 UI 狀態
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

    _controller.addListener(_videoValueListener);

    await _controller.initialize();
    await _controller.setLooping(true);
    await _controller.play();
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _videoValueListener());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

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

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_videoValueListener);
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

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
    final isTop = _categoryToIsTop(context, _selectedCategory); // ← 多語

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
    final l = S.of(context);
    final user = ref.watch(userProfileProvider);
    _isBroadcaster = user?.isBroadcaster == true;
    _selectedCategory = _isTopToCategory(context, widget.item.isTop);

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

            IgnorePointer(
              ignoring: true,
              child: AnimatedOpacity(
                opacity: _showSpinner ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),

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
                                  'VIP', // 此處維持原設計字樣
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AutoGrowTextField(
                          controller: _textController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          inputFormatters: [ LengthLimitingTextInputFormatter(_kMaxTitleLen) ],
                          maxLength: _kMaxTitleLen,
                          multiline: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),

                      if (_isBroadcaster) ...[
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedCategory == l.categoryFeatured
                                ? const Color(0xFFFF4D67)
                                : const Color(0xFF3A9EFF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                          ),
                          onPressed: () => _showCategoryBottomSheet(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_selectedCategory,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
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
    final l = S.of(context);
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
              Text(l.selectCategory,  // ← 多語
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  l.categoryFeatured, // ← 多語
                  style: TextStyle(
                    color: _selectedCategory == l.categoryFeatured
                        ? const Color(0xFFFF4D67)
                        : Colors.black,
                  ),
                ),
                onTap: () {
                  setState(() => _selectedCategory = l.categoryFeatured);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(
                  l.categoryDaily, // ← 多語
                  style: TextStyle(
                    color: _selectedCategory == l.categoryDaily
                        ? const Color(0xFF3A9EFF)
                        : Colors.black,
                  ),
                ),
                onTap: () {
                  setState(() => _selectedCategory = l.categoryDaily);
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