// 個人資料頁面
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/user_local_storage.dart';
import '../../data/models/user_model.dart';
import '../../l10n/l10n.dart';
import '../../routes/app_routes.dart';
import '../live/member_video_feed_state.dart';
import '../profile/profile_controller.dart';
import '../widgets/edit_profile_fullscreen_image_page.dart';
import '../widgets/edit_profile_fullscreen_video_player_page.dart';
import 'edit_profile_page.dart';

class EditMinePage extends ConsumerStatefulWidget {
  const EditMinePage({super.key});

  @override
  ConsumerState<EditMinePage> createState() => _EditMinePageState();
}

class _EditMinePageState extends ConsumerState<EditMinePage> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  final ScrollController _videoScrollController = ScrollController();
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier(0);
  final Map<String, Future<Uint8List?>> _thumbFutureCache = {};
  late String currentCity = "";

  Widget _buildProfileHeader(UserModel? user) {
    debugPrint('[_buildProfileHeader] user.photoURL=${ref.read(userProfileProvider)?.photoURL}');
    debugPrint('[_buildProfileHeader] user.photoURL=${ref.read(userProfileProvider)?.photoURLAbs}');
    // 先把空項目濾掉（避免被當成一張圖）
    final photos = (user?.photoURLAbs ?? [])
        .where((e) => e.trim().isNotEmpty)
        .toList(growable: false);

    // 沒有圖片 → 顯示預設圖
    if (photos.isEmpty) {
      return SizedBox(
        width: double.infinity,
        height: 288,
        child: Image.asset(
          'assets/my_photo_defult.jpeg',
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
      );
    }

    // 只有一張 → 單圖
    if (photos.length == 1) {
      return SizedBox(
        width: double.infinity,
        height: 288,
        child: _buildImageByPath(photos.first),
      );
    }

    // 兩張以上 → 輪播
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider.builder(
          key: ValueKey(photos.join('|')), // 用過濾後的清單做 key
          itemCount: photos.length,
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 288,
            viewportFraction: 1.0,
            autoPlay: true,
            onPageChanged: (index, reason) => _currentIndexNotifier.value = index,
          ),
          itemBuilder: (context, index, realIndex) => _buildImageByPath(photos[index]),
        ),
        Positioned(
          bottom: 12,
          child: ValueListenableBuilder<int>(
            valueListenable: _currentIndexNotifier,
            builder: (context, currentIndex, _) {
              return AnimatedSmoothIndicator(
                activeIndex: currentIndex.clamp(0, photos.length - 1),
                count: photos.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: Colors.white,
                  dotColor: Colors.white54,
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 6,
                ),
                onDotClicked: (index) => _carouselController.animateToPage(index),
              );
            },
          ),
        ),
      ],
    );
  }

  // 新增一個圖片載入判斷
  Widget _buildImageByPath(String path) {
    final p = path.trim();
    if (p.isEmpty) {
      return Image.asset('assets/my_photo_defult.jpeg',
          width: double.infinity, height: 288, fit: BoxFit.cover, alignment: Alignment.topCenter);
    }

    // ✅ iOS/Android 的本機絕對路徑
    final file = File(p);
    if (file.existsSync()) {
      return Image.file(file,
          width: double.infinity, height: 288, fit: BoxFit.cover, alignment: Alignment.topCenter);
    }

    // ✅ 網路圖（http/https）
    if (p.startsWith('http://') || p.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: p,
        width: double.infinity,
        height: 288,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorWidget: (_, __, ___) => Image.asset('assets/my_photo_defult.jpeg'),
      );
    }

    // 其他未知格式 → 預設圖
    return Image.asset('assets/my_photo_defult.jpeg',
        width: double.infinity, height: 288, fit: BoxFit.cover, alignment: Alignment.topCenter);
  }

  Widget buildMyProfileTab(UserModel? user) {
    final s = S.of(context);

    final height = user?.extra?['height'] ?? s.commonUnknown;
    final weight = user?.extra?['weight'] ?? s.commonUnknown;
    final body   = user?.extra?['body']   ?? s.commonUnknown;
    final city   = user?.city   ?? currentCity;
    final job    = user?.extra?['job']    ?? s.commonUnknown;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(s.profileAboutMe, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // '關於我'
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(flex:3, child: _InfoRow(label: s.profileLabelHeight, value: height)),
                    Expanded(flex:2, child: _InfoRow(label: s.profileLabelWeight, value: weight)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(flex:3, child: _InfoRow(label: s.profileLabelMeasurements, value: body)),
                    Expanded(flex:2, child: _InfoRow(label: s.profileLabelCity, value: city)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _InfoRow(label: s.profileLabelJob, value: job)),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if ((user?.tags ?? []).isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(s.profileMyTags, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // '我的標籤'
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user!.tags!.map((tag) => _TagChip(label: '#$tag')).toList(),
            ),
          ],
          const SizedBox(height: 50),
          Center(
            child: SizedBox(
              width: 280,
              height: 40,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF4D67), width: 1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                  if (!mounted) return;
                  _currentIndexNotifier.value = 0;
                  setState(() {});
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icon_edit.svg',
                      width: 20, height: 20,
                      colorFilter: const ColorFilter.mode(Color(0xFFFF4D67), BlendMode.srcIn),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.commonEdit, // '編輯'
                      style: const TextStyle(
                        color: Color(0xFFFF4D67),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget buildMyVideoTab(UserModel? user) {
    final s = S.of(context);
    final feed = ref.watch(memberFeedProvider);
    final notifier = ref.read(memberFeedProvider.notifier);

    final hasItems = feed.items.isNotEmpty;
    final isLoadingMore = hasItems && feed.isLoading;
    final isEmpty = feed.items.isEmpty;

    return RefreshIndicator(
      onRefresh: () async => notifier.loadFirstPage(int.parse(ref.watch(userProfileProvider)!.uid)),
      child: CustomScrollView(
        controller: _videoScrollController,
        cacheExtent: 3000,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(s.commonNoContentYet, style: TextStyle(color: Colors.grey[600])), // '還沒有內容'
                    const SizedBox(height: 70),
                  ],
                ),
              ),
            ),

          // 有資料：Grid
          if (hasItems)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 8 / 12,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = feed.items[index];
                    final hasCover = item.coverUrl != null && item.coverUrl!.isNotEmpty;
                    final isImage = !item.isVideo;

                    Widget mediaWidget;
                    if (hasCover) {
                      mediaWidget = CachedNetworkImage(
                        imageUrl: item.coverUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                        placeholder: (_, __) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      );
                    } else if (item.isVideo) {
                      mediaWidget = FutureBuilder<Uint8List?>(
                        future: _getNetworkVideoThumbnail(item.videoUrl),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.done && snap.hasData) {
                            return Image.memory(snap.data!, width: double.infinity, height: double.infinity, fit: BoxFit.cover);
                          }
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        },
                      );
                    } else if (isImage) {
                      mediaWidget = CachedNetworkImage(
                        imageUrl: item.videoUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                        placeholder: (_, __) => Container(
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                      );
                    } else {
                      mediaWidget = Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.insert_drive_file)),
                      );
                    }

                    return GestureDetector(
                      onTap: () async {
                        if (item.isVideo) {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullscreenVideoPlayerPage(item: item),
                            ),
                          );
                          if (result is Map && result['updated'] == true) {
                            ref.read(memberFeedProvider.notifier).applyLocalUpdate(
                              id: result['id'] as int,
                              title: result['title'] as String,
                              isTop: result['isTop'] as int,
                            );
                          }
                        } else {
                          final img = hasCover ? item.coverUrl! : (isImage ? item.videoUrl : '');
                          if (img.isNotEmpty) {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => FullscreenImagePage(item: item)),
                            );
                            if (result is Map && result['updated'] == true) {
                              ref.read(memberFeedProvider.notifier).applyLocalUpdate(
                                id: result['id'] as int,
                                title: result['title'] as String,
                                isTop: result['isTop'] as int,
                              );
                            }
                          }
                        }
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                ClipRRect(borderRadius: BorderRadius.circular(12), child: mediaWidget),
                                if (item.isVideo)
                                  const Positioned.fill(
                                    child: Center(child: Icon(Icons.play_circle_fill, size: 36, color: Colors.white)),
                                  ),
                                if (item.isTop == 1)
                                  Positioned(
                                    bottom: 6, left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(4)),
                                      child: Text(s.commonFeatured, style: TextStyle(color: Colors.white, fontSize: 10)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.title.isEmpty
                                ? (item.isVideo ? s.commonVideo : (isImage ? s.commonImage : s.commonContent))
                                : item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: feed.items.length,
                ),
              ),
            ),

          // CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric( vertical: 50),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.videoRecorder),
                  child: Container(
                    width: 288,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFB56B), Color(0xFFDF65F8)]),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset('assets/icon_start_video.svg', width: 24, height: 24),
                          const SizedBox(width: 6),
                          Text(s.commonPublishMoment, style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Future<Uint8List?> _getNetworkVideoThumbnail(String videoUrl) {
    // 避免同一個 URL 重複計算
    if (_thumbFutureCache.containsKey(videoUrl)) return _thumbFutureCache[videoUrl]!;

    final future = (() async {
      try {
        final tmpDir = await getTemporaryDirectory();
        final fileName = videoUrl.split('/').last;
        final localPath = '${tmpDir.path}/thumb_src_$fileName';
        final f = File(localPath);

        if (!await f.exists()) {
          final resp = await Dio().get<List<int>>(videoUrl,
              options: Options(responseType: ResponseType.bytes));
          await f.writeAsBytes(resp.data as List<int>);
        }

        return await VideoThumbnail.thumbnailData(
          video: f.path,
          imageFormat: ImageFormat.PNG,
          maxWidth: 256, // 比 128 再清楚一些
          quality: 75,
        );
      } catch (e) {
        debugPrint('🎬 Failed to gen network thumbnail: $e');
        return null;
      }
    })();

    _thumbFutureCache[videoUrl] = future;
    return future;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final currentUser = await UserLocalStorage.getUser();
      if (currentUser == null) return;

      final userRepo = ref.read(userRepositoryProvider);
      final updatedUser = await userRepo.getMemberInfo(currentUser);

      await UserLocalStorage.saveUser(updatedUser);
      final prev = ref.read(userProfileProvider);
      final merged = (prev == null)
          ? updatedUser
          : updatedUser.copyWith(gold: prev.gold, vipExpire: prev.vipExpire);
      ref.read(userProfileProvider.notifier).setUser(merged);
      ref.read(memberFeedProvider.notifier).loadFirstPage(int.parse(ref.watch(userProfileProvider)!.uid));
    });

    // 接近動態底部時抓下一頁
    _videoScrollController.addListener(() {
      final s = ref.read(memberFeedProvider);
      if (s.isLoading || !s.hasMore) return;
      final pos = _videoScrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 400) {
        ref.read(memberFeedProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final s = S.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            user?.displayName ?? s.commonMyProfile, // '個人資料'
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          leading: const BackButton(color: Colors.white),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TabBar(
                labelColor: const Color(0xFFFF4D67),
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 16),
                indicatorColor: const Color(0xFFFF4D67),
                indicatorWeight: 2,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: s.profileTabInfo),    // '我的資料'
                  Tab(text: s.profileTabMoments), // '個人動態'
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  buildMyProfileTab(user),
                  buildMyVideoTab(user),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoScrollController.dispose();
    _currentIndexNotifier.dispose();
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text('$label：', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.black, fontSize: 14)),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: const BoxDecoration(color: Color(0xFFFFEBEF)),
      child: Text(label, style: const TextStyle(color: Colors.pink, fontSize: 13)),
    );
  }
}
