// # 第一個頁籤內容
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../call/call_request_page.dart';
import '../live/live_user_info_card.dart';
import '../profile/view_profile_page.dart';

class LiveListPage extends StatefulWidget {
  final ValueChanged<int>? onTabChanged;
  final bool isMale;

  const LiveListPage({
    super.key,
    this.onTabChanged,
    required this.isMale
  });

  @override
  State<LiveListPage> createState() => _LiveListPageState();
}

class _LiveListPageState extends State<LiveListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, String>> mockUsers = List.generate(8, (index) {
    final imgIndex = (index % 4) + 1;
    return {
      'broadcaster': 'broadcaster00$index',
      'name': 'Ariana Flores $index',
      'image': 'assets/pic_girl$imgIndex.png',
      'videoPath': 'assets/demo_video$imgIndex.mp4',
    };
  });

  late final HomeVideoTab _homeVideoTab;


  @override
  void initState() {
    super.initState();

    _homeVideoTab = HomeVideoTab(usersList: mockUsers);

    // 如果不是男生，才初始化 TabController
    if (!widget.isMale) {
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
  }

  @override
  void dispose() {
    if (!widget.isMale) {
      _tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMale) {
      // 只顯示首頁內容
      return Scaffold(
        body: SafeArea(top: false, child: _homeVideoTab),
      );
    }

    // 保持原本兩個 tab 的邏輯
    return Scaffold(
      body: Stack(
        children: [
          _tabController.index == 0
              ? SafeArea(top: false, child: _homeVideoTab)
              : SafeArea(child: _buildFriendListView()),
          SafeArea(
            child: Container(
              color: _tabController.index == 0 ? Colors.transparent : Colors.white,
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
          ),
        ],
      ),
    );
  }

  Widget _buildFriendListView() {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 60),
        child: GridView.builder(
          padding: const EdgeInsets.only(bottom: 16, top: 56),
          itemCount: mockUsers.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final user = mockUsers[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ViewProfilePage(
                      displayName: user['name']!,
                      avatarPath: user['image']!,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      user['image']!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(user['image']!),
                        radius: 12,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          user['name']!,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SvgPicture.asset('assets/logo_placeholder2.svg', height: 24,width: 24,),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class HomeVideoTab extends StatefulWidget {
  final List<Map<String, String>> usersList;
  const HomeVideoTab({super.key, required this.usersList});

  @override
  State<HomeVideoTab> createState() => _HomeVideoTabState();
}

class _HomeVideoTabState extends State<HomeVideoTab>
    with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _initialPage = 5000;
  int _currentPage = 5000;
  final int _bufferSize = 2;
  bool _initialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized && _pageController.hasClients) {
        _pageController.jumpToPage(_initialPage);
        setState(() {
          _currentPage = _initialPage;
          _initialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          final page = _pageController.page?.round();
          if (page != null && page != _currentPage) {
            setState(() {
              _currentPage = page;
            });
          }
        }
        return false;
      },
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          final actualIndex = index % widget.usersList.length;
          final user = widget.usersList[actualIndex];

          if ((index - _currentPage).abs() > _bufferSize) {
            return const SizedBox();
          }

          final videoIndex = (index % 4) + 1;
          final videoPath = 'assets/demo_video$videoIndex.mp4';
          return _LiveVideoItem(
            videoPath: videoPath,
            name: user['name']!,
            image: user['image']!,
            isActive: index == _currentPage,
          );
        },
      ),
    );
  }
}

class _LiveVideoItem extends StatefulWidget {
  final String videoPath;
  final String name;
  final String image;
  final bool isActive;

  const _LiveVideoItem({
    required this.videoPath,
    required this.name,
    required this.image,
    required this.isActive,
  });

  @override
  State<_LiveVideoItem> createState() => _LiveVideoItemState();
}

class _LiveVideoItemState extends State<_LiveVideoItem> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  bool _isVisible = true; // 控制頁面是否可見
  bool _isControllerDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = VideoPlayerController.asset(widget.videoPath);
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        _controller.setLooping(true);
        if (widget.isActive && _isVisible) {
          _controller.play();
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant _LiveVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (mounted && !_isControllerDisposed && _controller.value.isInitialized) {
      if (!oldWidget.isActive && widget.isActive) {
        _controller.play();
      }
      if (oldWidget.isActive && !widget.isActive) {
        _controller.pause();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted && !_isControllerDisposed && _controller.value.isInitialized) {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        _controller.pause();
      } else if (state == AppLifecycleState.resumed && widget.isActive) {
        _controller.play();
      }
    }
  }

  @override
  void dispose() {
    _isControllerDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('LiveVideoItem-${widget.name}'),
      onVisibilityChanged: (info) {
        final visible = info.visibleFraction > 0.5;
        if (_isVisible != visible) {
          _isVisible = visible;
          if (mounted && !_isControllerDisposed && _controller.value.isInitialized) {
            if (visible && widget.isActive) {
              _controller.play();
            } else {
              _controller.pause();
            }
          }
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: _controller.value.isInitialized
                ? FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
                : const Center(child: CircularProgressIndicator()),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 220,
            child: GestureDetector(
              onTap: _handleCallRequest,
              child: SvgPicture.asset(
                'assets/live_start_1.svg',
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 96,
            child: LiveUserInfoCard(
              name: widget.name,
              avatarPath: widget.image,
              rateText: '100美元/分鐘',
              tags: ['女 19', '御姐', '高顏值', '運動'],
            ),
          ),
        ],
      ),
    );
  }

  void _handleCallRequest() {
    final broadcasterId = widget.name ?? '';
    final broadcasterName = widget.name ?? '主播';
    final broadcasterImage = widget.image ?? 'assets/default.jpg';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallRequestPage(
          broadcasterId: broadcasterId,
          broadcasterName: broadcasterName,
          broadcasterImage: broadcasterImage,
        ),
      ),
    );
  }
}