// # 第一個頁籤內容
import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../platform/cached_prefetch.dart';
import '../../routes/app_routes.dart';
import '../call/call_request_page.dart';
import '../live/data_model/cached_player_view.dart';
import '../live/data_model/feed_item.dart';
import '../live/data_model/home_feed_state.dart';
import '../live/data_model/prefetch_manager.dart';
import '../live/live_user_info_card.dart';
import '../live/video_repository_provider.dart';
import '../mine/user_repository_provider.dart';
import '../profile/profile_controller.dart';
import '../profile/view_profile_page.dart';

class LiveListPage extends ConsumerStatefulWidget {
  final ValueChanged<int>? onTabChanged;
  final bool isBroadcaster;

  const LiveListPage({
    super.key,
    this.onTabChanged,
    required this.isBroadcaster,
  });

  @override
  ConsumerState<LiveListPage> createState() => _LiveListPageState();
}

class _LiveListPageState extends ConsumerState<LiveListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  late final HomeVideoTab _homeVideoTab;


  @override
  void initState() {
    super.initState();

    _homeVideoTab = const HomeVideoTab();

    // 如果是主播，才初始化 TabController
    if (widget.isBroadcaster) {
      _tabController = TabController(length: 2, vsync: this)
        ..addListener(() {
          if (!_tabController.indexIsChanging) {
            widget.onTabChanged?.call(_tabController.index);
            setState(() {});
          }
        });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTabChanged?.call(_tabController.index);
      });
    }

    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      ref.read(friendListProvider.notifier).loadFirstPage();
    });
  }

  void _onScroll() {
    final notifier = ref.read(friendListProvider.notifier);
    final scroll = _scrollController;
    if (!scroll.hasClients) return;
    if (scroll.position.pixels >= scroll.position.maxScrollExtent - 300) {
      notifier.loadNextPage();
    }
  }

  @override
  void dispose() {
    if (widget.isBroadcaster) {
      _tabController.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isBroadcaster) {
      // 只顯示首頁內容
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(top: false, bottom: false, child: _homeVideoTab),
      );
    }
    // 主播 保持原本兩個 tab 的邏輯
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _tabController.index == 0
              ? SafeArea(top: false, bottom: false, child: _homeVideoTab)
              : SafeArea( bottom: false, child: _buildFriendListView()),
          SafeArea(
            child: Container(
              color: _tabController.index == 0 ? Colors.transparent : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: _tabController.index == 0 ? Colors.white : Colors.black,
                      unselectedLabelColor:
                      _tabController.index == 0 ? Colors.white70 : Colors.grey,
                      labelStyle:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      unselectedLabelStyle: const TextStyle(fontSize: 18),
                      indicatorColor:
                      _tabController.index == 0 ? Colors.white : Colors.black,
                      indicatorWeight: 2,
                      indicatorSize: TabBarIndicatorSize.label,
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.only(right: 20),
                      tabs: const [
                        Tab(text: '首页'),
                        Tab(text: '交友'),
                      ],
                    ),
                  ),
                  // 右側 发布动态（只有主播顯示）
                  if (widget.isBroadcaster)
                    _PublishButton(
                      darkBg: _tabController.index == 0, // 首頁是深/透明背景，用白色字
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendListView() {
    final state = ref.watch(friendListProvider);
    final cdnUrl = ref.watch(userProfileProvider)?.cdnUrl ?? '';

    return SafeArea(
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 76, 12, 60),
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  itemCount: state.users.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final user = state.users[index];
                    final avatarRaw = user.photoURL.isNotEmpty
                        ? user.photoURL.first
                        : '';
                    final avatarUrl = avatarRaw.startsWith('http')
                        ? avatarRaw
                        : '$cdnUrl$avatarRaw';
      
                    final image = (avatarUrl.isNotEmpty)
                        ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      memCacheWidth: (MediaQuery.of(context).size.width / 2 * MediaQuery.of(context).devicePixelRatio).round(), // 單格寬
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Image.asset('assets/my_icon_defult.jpeg', fit: BoxFit.cover),
                    )
                        : Image.asset('assets/my_icon_defult.jpeg', fit: BoxFit.cover);
      
                    return AspectRatio(
                      aspectRatio: 3 / 4,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewProfilePage(
                                  userId: int.parse(user.uid),
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              // 背景圖片
                              Positioned.fill(child: image),
      
                              // 底部遮罩 + 名稱 + icon
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [Colors.black54, Colors.transparent],
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user.displayName ?? '用戶',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            shadows: [
                                              Shadow(blurRadius: 2, color: Colors.black45)
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

}

class HomeVideoTab extends ConsumerStatefulWidget {
  const HomeVideoTab({super.key});

  @override
  ConsumerState<HomeVideoTab> createState() => _HomeVideoTabState();
}

class _HomeVideoTabState extends ConsumerState<HomeVideoTab>
    with AutomaticKeepAliveClientMixin, RouteAware {

  static const int _seedPage = 10000;
  final PageController _pageController = PageController(initialPage: _seedPage);
  int _currentVirtualPage = _seedPage;
  bool _jumpedToSeed = true; // 直接視為已跳

  @override
  bool get wantKeepAlive => true;

  // HLS/MP4 預載用
  final Map<int, CancelToken> _prefetchCancels = {};
  final Map<int, String> _mp4PrefetchHandles = {};

  final ValueNotifier<bool> _playGate = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeFeedProvider.notifier).loadFirst();
    });

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      routeObserver.subscribe(this, route); // ← 訂閱
    }
  }

  // 當「有新頁面推上來覆蓋」
  @override
  void didPushNext() {
    _playGate.value = false; // 全部暫停
  }

  // 當「上層頁面 pop 回來」：
  @override
  void didPopNext() {
    _playGate.value = true;  // 恢復播放
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _playGate.dispose();
    _pageController.dispose();
    // 不再持有多支 controller，這裡不用逐一 dispose
    for (final cancel in _prefetchCancels.values) { cancel(); }
    super.dispose();
  }

  int _wrapIndex(int i, int len) { var r = i % len; if (r < 0) r += len; return r; }
  Set<int> _wantedWindow(int center, int len) {
    const offs = [-2, -1, 0, 1, 2];
    return offs.map((o) => _wrapIndex(center + o, len)).toSet();
  }

  Future<void> _maintainWindow(List<FeedItem> items, int centerReal) async {
    if (items.isEmpty) return;
    final len = items.length;
    final wanted = _wantedWindow(centerReal, len);

    // 資料層預載：HLS/MP4
    for (final idx in wanted) {
      final it = items[idx];
      if (it.kind != FeedKind.video || it.videoUrl == null) continue;

      final url = it.videoUrl!;
      final isHls = url.toLowerCase().contains('.m3u8');

      if (isHls) {
        _prefetchCancels.remove(idx)?.call();
        _prefetchCancels[idx] = PlatformPrefetch.prefetchHlsHead(url, headSegments: 4);
      } else {
        // 只預取 MP4 首段，不建 ExoPlayer
        if (!_mp4PrefetchHandles.containsKey(idx)) {
          final handle = await CachedPrefetch.mp4Head(url, bytes: 3 * 1024 * 1024);
          _mp4PrefetchHandles[idx] = handle;
        }
      }
    }

    // 清理離窗的預載
    final obsoleteMp4 = _mp4PrefetchHandles.keys.where((k) => !wanted.contains(k)).toList();
    for (final k in obsoleteMp4) {
      final id = _mp4PrefetchHandles.remove(k);
      if (id != null) await CachedPrefetch.cancel(id);
    }
    final obsoleteHls = _prefetchCancels.keys.where((k) => !wanted.contains(k)).toList();
    for (final k in obsoleteHls) {
      _prefetchCancels.remove(k)?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final allow = ref.watch(homePlayGateProvider);
    if (_playGate.value != allow) {
      _playGate.value = allow;
    }

    final feed = ref.watch(homeFeedProvider);
    final ctl  = ref.read(homeFeedProvider.notifier);
    final items = feed.items;

    if (items.isNotEmpty && !_jumpedToSeed && _pageController.hasClients) {
      _pageController.jumpToPage(_seedPage);
      _currentVirtualPage = _seedPage;
      _jumpedToSeed = true;
      _maintainWindow(items, _wrapIndex(_currentVirtualPage, items.length));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification && _pageController.hasClients && items.isNotEmpty) {
          final page = _pageController.page?.round();
          if (page != null && page != _currentVirtualPage) {
            setState(() => _currentVirtualPage = page);
            final real = _wrapIndex(_currentVirtualPage, items.length);
            ctl.loadMoreIfNeeded(real);
            _maintainWindow(items, real);
          }
        }
        return false;
      },
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, virtualIndex) {
          if (items.isEmpty) return const Center(child: CircularProgressIndicator());
          final len = items.length;
          final realIndex = _wrapIndex(virtualIndex, len);
          final item = items[realIndex];

          // 預緩存下一張封面（降記憶體）
          final nextReal = _wrapIndex(realIndex + 1, len);
          final nextCover = items[nextReal].coverCandidate;
          if (nextCover != null && nextCover.isNotEmpty) {
            final mq = MediaQuery.of(context);
            final w  = (mq.size.width * mq.devicePixelRatio).round();
            precacheImage(ResizeImage(NetworkImage(nextCover), width: w), context);
          }

          final isActive = virtualIndex == _currentVirtualPage;

          switch (item.kind) {
            case FeedKind.video:
              return _VideoCard(
                key: ValueKey(item.videoUrl), // or ValueKey(item.id)
                item: item,
                isActive: isActive,
                playGate: _playGate,
              );
            case FeedKind.image:
              return _ImageCard(
                key: ValueKey('img_${item.coverCandidate ?? item.id}'),
                item: item,
                playGate: _playGate,
              );
          }

        },
      ),
    );
  }

  void skipToNext() {
    if (!_pageController.hasClients) return;
    final next = (_pageController.page?.round() ?? _currentVirtualPage) + 1;
    _pageController.animateToPage(next, duration: const Duration(milliseconds: 260), curve: Curves.easeInOut);
    _currentVirtualPage = next;
    final items = ref.read(homeFeedProvider).items;
    if (items.isNotEmpty) {
      final real = _wrapIndex(next, items.length);
      ref.read(homeFeedProvider.notifier).loadMoreIfNeeded(real);
      _maintainWindow(items, real);
    }
  }
}

class _CallButton extends ConsumerWidget {
  final FeedItem item;
  const _CallButton({required this.item});

  CalleeState _mapToCalleeState(FeedItem it) {
    // 推荐：后端 raw 数字：1=online, 2=offline, 3=busy
    final int? raw = it.onlineStatusRaw; // 你之前就有这个字段

    if (raw != null) {
      switch (raw) {
        case 1:
        case 2: return CalleeState.online;
        case 3:
        case 4:
        case 5: return CalleeState.busy;
        default: return CalleeState.offline;
      }
    }

    // 兜底：如果只有字符串或其它形式
    final s = it.onlineStatus.toString().toLowerCase();
    if (s == 'busy' || s == '3') return CalleeState.busy;
    if (s == 'online' || s == '1') return CalleeState.online;
    return CalleeState.offline;
  }

  Future<void> _handleCallRequest(BuildContext context, WidgetRef ref) async {
    final broadcasterId   = item.uid.toString();
    final broadcasterName = (item.nickName?.isNotEmpty == true)
        ? item.nickName!
        : (item.title.isEmpty ? '主播' : item.title);
    final broadcasterImage = item.firstAvatar ?? item.coverCandidate ?? 'assets/default.jpg';

    // ★ 進入撥打頁前，先把首頁影片關掉
    ref.read(homePlayGateProvider.notifier).state = false;

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallRequestPage(
            broadcasterId: broadcasterId,
            broadcasterName: broadcasterName,
            broadcasterImage: broadcasterImage,
            isVideoCall: true,
            calleeState: _mapToCalleeState(item),
          ),
        ),
      );
    } finally {
      // ★ 返回首頁後，再打開
      if (context.mounted) {
        ref.read(homePlayGateProvider.notifier).state = true;
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 220,
      child: GestureDetector(
        onTap: () => _handleCallRequest(context, ref),
        child: SvgPicture.asset('assets/live_start_1.svg'),
      ),
    );
  }
}

class _VideoCard extends ConsumerStatefulWidget {

  final FeedItem item;
  final bool isActive;
  final ValueListenable<bool> playGate;
  const _VideoCard({required Key? key, required this.item, required this.isActive, required this.playGate});

  @override
  ConsumerState<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends ConsumerState<_VideoCard> with WidgetsBindingObserver {
  final _viewKey = GlobalKey<CachedPlayerViewState>();
  bool _attached = false;
  bool _coverVisible = true;
  VoidCallback? _gateListener;
  Timer? _watchdog;

  bool get _isUserInteracting {
    final pos = Scrollable.of(context)?.position;
    return (pos?.isScrollingNotifier.value ?? false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 監聽播放閘門：false → 暫停並 detach；true 且本卡 active → attach+play
    _gateListener = () {
      final allowPlay = widget.playGate.value;
      if (!allowPlay) {
        _detachAndPause();
      } else if (allowPlay && widget.isActive) {
        _attachAndPlay();
      }
    };
    widget.playGate.addListener(_gateListener!);

    // 剛建好如果就是 active，等 PlatformView 初始化完就 attach+play
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isActive && widget.playGate.value) _attachAndPlay();
    });
  }

  String joinUrl(String base, String p) {
    if (p.isEmpty) return '';
    if (p.startsWith('http')) return p;
    if (base.isEmpty) return p;
    return p.startsWith('/') ? '$base$p' : '$base/$p';
  }

  Future<void> _attachAndPlay() async {
    if (!mounted || _attached) return;
    try {
      await _viewKey.currentState?.attach();
      await _viewKey.currentState?.play();

      _watchdog?.cancel();
      _watchdog = Timer(const Duration(milliseconds: 800), () async {
        if (!mounted) return;
        if (_coverVisible && !_isUserInteracting) {
          // 只做一次熱插拔
          _watchdog?.cancel();
          try {
            await _viewKey.currentState?.detach();
            await _viewKey.currentState?.attach();
            await _viewKey.currentState?.play();
          } catch (_) {}
        }
      });

      if (mounted) setState(() { _attached = true; /* 不動 _coverVisible */ });
    } catch (_) {}
  }

  Future<void> _detachAndPause() async {
    _watchdog?.cancel();
    if (!mounted) return;
    try {
      await _viewKey.currentState?.pause();
      await _viewKey.currentState?.detach();
      // 小延遲，給原生釋放 Surface/Buffer 時間
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (_) {}
    if (mounted) {
      setState(() {
        _attached = false;
        _coverVisible = true; // 👈 離場就把封面顯示回來
      });
    }
  }

  @override
  void didUpdateWidget(covariant _VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.videoUrl != oldWidget.item.videoUrl) {
      setState(() => _coverVisible = true); // 切新片，先顯示封面
    }
    if (!oldWidget.isActive && widget.isActive) {
      _attachAndPlay();        // 不隱藏封面
    } else if (oldWidget.isActive && !widget.isActive) {
      _detachAndPause();       // 顯示封面
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
      // 回前台：只有當前卡片是 active 才重新綁上 Surface 並播放
        if (widget.isActive) {
          _attachAndPlay();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      // 進背景/半活躍：切乾淨，避免持有舊 Surface 或卡 codec
        _detachAndPause();
        break;
      case AppLifecycleState.detached:
      // App 要被銷毀：把 native 資源放掉
        _viewKey.currentState?.detach();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _watchdog?.cancel();
    _viewKey.currentState?.detach();
    widget.playGate.removeListener(_gateListener!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(userProfileProvider)?.uid;
    final url   = widget.item.videoUrl!;
    final cover = widget.item.coverCandidate;

    final displayName  = (widget.item.nickName?.isNotEmpty == true)
        ? widget.item.nickName! : (widget.item.title.isEmpty ? ' ' : widget.item.title);
    final displayAvatarRaw = widget.item.firstAvatar ?? (cover ?? '');
    final displayTags   = widget.item.tags.isNotEmpty ? widget.item.tags : const ['推薦', '新上傳'];
    final cdn = ref.watch(userProfileProvider)?.cdnUrl ?? '';
    final avatarUrl = joinUrl(cdn, displayAvatarRaw);
    if (avatarUrl.isNotEmpty) {
      precacheImage(CachedNetworkImageProvider(avatarUrl), context); // 可選：滑到時更穩
    }

    return Stack(
      children: [
        // 播放器（預設不自動 attach，不佔 decoder）
        Positioned.fill(
          child: CachedPlayerView(
            key: _viewKey,
            url: url,
            autoPlayOnAttach: widget.isActive,
            coverUrl: cover,
            onFirstFrame: () {
              if (!mounted) return;
              _watchdog?.cancel();
              setState(() => _coverVisible = false);
            },
          ),
        ),
        if (cover != null && _coverVisible)
          Positioned.fill(
            child: Image(
              image: ResizeImage(
                CachedNetworkImageProvider(cover),
                width: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).round(),
              ),
              fit: BoxFit.cover,
            ),
          ),
        if(myUid != null && widget.item.uid.toString() != myUid)
          _CallButton(item: widget.item),
        Positioned(
          left: 16, right: 16, bottom: 96,
          child: // _VideoCard.build 內
          LiveUserInfoCard(
            uid: widget.item.uid,
            name: displayName,
            avatarPath: avatarUrl,
            rateText: '${widget.item.pricePerMinute}金幣/分鐘',
            tags: displayTags,
            isLike: widget.item.isLike,
            status: widget.item.onlineStatus,
            onToggleLike: (liked) async {
              final notifier = ref.read(homeFeedProvider.notifier);
              // 1) 樂觀更新（擇一：對人或對片）
              notifier.setLikeByUser(uid: widget.item.uid, liked: liked);

              // 2) 背景請求（成功就沒事，失敗回滾）
              final svc = ref.read(backgroundApiServiceProvider);
              try {
                // 如果你的「讚」是對人
                await svc.likeUserAndRefresh(targetUid: widget.item.uid.toString());
              } catch (e) {
                // 回滾
                notifier.setLikeByUser(uid: widget.item.uid, liked: !liked);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ImageCard extends ConsumerStatefulWidget {
  final FeedItem item;
  final ValueListenable<bool> playGate;
  const _ImageCard({required Key? key, required this.item, required this.playGate});

  @override
  ConsumerState<_ImageCard> createState() => _ImageCardState();
  }

class _ImageCardState extends ConsumerState<_ImageCard> with WidgetsBindingObserver {

  @override
  Widget build(BuildContext context) {
    final myUid = ref.watch(userProfileProvider)?.uid;
    final img = widget.item.coverCandidate;
    final displayName = (widget.item.nickName?.isNotEmpty == true)
        ? widget.item.nickName!
        : (widget.item.title.isEmpty ? ' ' : widget.item.title);
    final displayAvatar = widget.item.avatar.first;
    final displayTags = widget.item.tags.isNotEmpty ? widget.item.tags : const ['圖片'];

    return Stack(
      children: [
        Positioned.fill(
          child: img != null
              ? CachedNetworkImage(
            imageUrl: img,
            memCacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).round(),
            fit: BoxFit.cover,
            placeholder: (context, url) =>
            const ColoredBox(color: Colors.black),
            errorWidget: (context, url, error) =>
            const ColoredBox(color: Colors.black12),
          )
              : const ColoredBox(color: Colors.black12),
        ),
        if(myUid != null && widget.item.uid.toString() != myUid)
          _CallButton(item: widget.item),
        Positioned(
          left: 16,
          right: 16,
          bottom: 96,
          child: LiveUserInfoCard(
            uid: widget.item.uid,
            name: displayName,
            avatarPath: displayAvatar,
            rateText: '${widget.item.pricePerMinute}金幣/分鐘',
            tags: displayTags,
            isLike: widget.item.isLike,
            status: widget.item.onlineStatus,
            onToggleLike: (liked) async {
              final notifier = ref.read(homeFeedProvider.notifier);
              // 1) 樂觀更新
              notifier.setLikeByUser(uid: widget.item.uid, liked: liked);

              // 2) 背景請求（成功就沒事，失敗回滾）
              final svc = ref.read(backgroundApiServiceProvider);
              try {
                // 「讚」是對人
                await svc.likeUserAndRefresh(targetUid: widget.item.uid.toString());
              } catch (e) {
                // 回滾
                notifier.setLikeByUser(uid: widget.item.uid, liked: !liked);
              }
            },
          ),
        ),
      ],
    );
  }
}

typedef CancelToken = void Function();

class _PublishButton extends StatelessWidget {
  final bool darkBg;                // 當前 TabBar 背景是否為深色（首頁）

  const _PublishButton({
    required this.darkBg,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.videoRecorder),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.transparent.withOpacity(0.3), // 背景透明
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset('assets/icon_add.svg'),
            const SizedBox(width: 4),
            const Text(
              '发布动态',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
