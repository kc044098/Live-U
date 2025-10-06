// 檢視其他人的個人資料
import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:djs_live_stream/features/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../data/models/member_video_model.dart';
import '../../data/models/user_model.dart';
import '../../l10n/l10n.dart';
import '../call/call_request_page.dart';
import '../live/data_model/feed_item.dart';
import '../live/data_model/home_feed_state.dart';
import '../live/member_video_feed_state.dart';
import '../message/message_chat_page.dart';
import '../mine/user_repository_provider.dart';
import '../widgets/view_other_image_page.dart';
import '../widgets/view_other_video_page.dart';

class ViewProfilePage extends ConsumerStatefulWidget {
  final int userId;

  const ViewProfilePage({super.key, required this.userId});

  @override
  ConsumerState<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends ConsumerState<ViewProfilePage> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final ScrollController _feedScroll = ScrollController();
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier(0);
  final ValueNotifier<double> scaleNotifier = ValueNotifier(1.0);

  final Map<String, Future<Uint8List?>> _thumbFutureCache = {};

  @override
  void initState() {
    super.initState();
    // ✅ 首次載入指定用戶的動態
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(memberFeedByUserProvider(widget.userId).notifier)
          .loadFirstPage(widget.userId);
    });

    // ✅ 監聽滑到底自動載入下一頁
    _feedScroll.addListener(() {
      if (!_feedScroll.hasClients) return;
      final position = _feedScroll.position;
      if (position.pixels > position.maxScrollExtent - 400) {
        ref
            .read(memberFeedByUserProvider(widget.userId).notifier)
            .loadNextPage();
      }
    });
  }

  Future<Uint8List?> _getNetworkVideoThumbnail(String videoUrl) {
    // 避免同一個 URL 重複計算
    if (_thumbFutureCache.containsKey(videoUrl))
      return _thumbFutureCache[videoUrl]!;

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

  Widget buildMyProfileTab(UserModel? user, bool effectiveIsLike) {
    final t = S.of(context);
    // 從 user.extra 中讀取擴展資料（假設後端返回了身高、體重等資訊）
    String height = user?.extra?['height'] ?? t.unknown;
    String weight = user?.extra?['weight'] ?? t.unknown;
    final body = user?.extra?['body'] ?? t.unknown;
    final city = user?.extra?['city'] ?? t.unknown;
    final job = user?.extra?['job'] ?? t.unknown;

    if (height != t.unknown && !height.contains(t.unitCm)) {
      height = '$height ${t.unitCm}';
    }
    if (weight != t.unknown && !weight.contains(t.unitLb) && !weight.contains(t.unitKg)) {
      weight = '$weight ${t.unitLb}';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFeaturedStripIfNeeded(user),
          const SizedBox(height: 12),
          Text(t.profileAboutMe, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    Expanded(flex:2, child: _InfoRow(label: t.profileHeight, value: height)),
                    Expanded(flex:1, child: _InfoRow(label: t.profileWeight, value: weight)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(flex:2, child: _InfoRow(label: t.profileMeasurements, value: body)),
                    Expanded(flex:1, child: _InfoRow(label: t.profileCity, value: city)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _InfoRow(label: t.profileJob, value: job)),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if ((user?.tags ?? []).isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(t.profileMyTags, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  user!.tags!.map((tag) => _TagChip(label: '#$tag')).toList(),
            ),
          ],
          const SizedBox(height: 50),
          buildButtonView(user, effectiveIsLike),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget buildButtonView(UserModel? u, bool effectiveIsLike) {
    final t = S.of(context);
    if (u == null) return const SizedBox.shrink();
    final myUid = ref.watch(userProfileProvider)?.uid;
    if (myUid != null && u.uid.toString() == myUid) return const SizedBox(height: 4);

    final liked = effectiveIsLike;
    const double kBtnH = 44;
    const double kGap = 6;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ❤️ 固定寬度的愛心
        SizedBox(
          width: 48,
          child: Column(
            children: [
              ValueListenableBuilder<double>(
                valueListenable: scaleNotifier,
                builder: (_, scale, __) => GestureDetector(
                  onTap: () => _toggleLike(u, liked),
                  child: AnimatedScale(
                    scale: scale,
                    duration: const Duration(milliseconds: 150),
                    child: SvgPicture.asset(
                      liked ? 'assets/live_heart_filled2.svg' : 'assets/live_heart2.svg',
                      width: 40, height: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),

        const SizedBox(width: kGap),

        // 💬 私信 —— 3 份寬
        Expanded(
          flex: 3,
          child: SizedBox(
            height: kBtnH,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.pink),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, kBtnH),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessageChatPage(
                      partnerName: _partnerName(u),
                      partnerAvatar: u.avatarUrl,
                      vipLevel: (u.isVip == true) ? 1 : 0,
                      statusText: u.status ?? 0,
                      partnerUid: int.parse(u.uid),
                    ),
                  ),
                );
              },
              child: FittedBox(child: Text(t.actionMessageTa, style: const TextStyle(color: Colors.pink))),
            ),
          ),
        ),

        const SizedBox(width: kGap),

        // 🎥 發起視頻 —— 5 份寬（含下方價格）
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: kBtnH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFFB56B), Color(0xFFDF65F8)]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => _handleCallRequest(u),
                    child: FittedBox(
                      child: FittedBox(child: Text(t.actionStartVideo, style: const TextStyle(color: Colors.white, fontSize: 14))),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              if (u.videoPrice != null && u.isBroadcaster)
                Text(
                  (u.videoPrice != null && u.videoPrice! <= 0)
                      ? t.free
                      : t.coinsPerMinute(u.videoPrice!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),

            ],
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  void _toggleLike(UserModel current, bool currentLiked) {
    // 動效（僅縮放，不改 like 狀態）
    scaleNotifier.value = 3.0;
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) scaleNotifier.value = 1.0;
    });

    final nextLiked = !currentLiked;

    // 1) 立刻同步到首頁推薦列表（此人所有卡片）
    ref.read(homeFeedProvider.notifier).setLikeByUser(
      uid: int.parse(current.uid),
      liked: nextLiked,
    );

    // 2) 背景 API；失敗回滾
    final svc = ref.read(backgroundApiServiceProvider);
    unawaited(
      svc.likeUserAndRefresh(targetUid: current.uid).catchError((e, st) {
        // 回滾首頁列表
        ref.read(homeFeedProvider.notifier).setLikeByUser(
          uid: int.parse(current.uid),
          liked: currentLiked,
        );
      }),
    );
  }

  void _handleCallRequest(UserModel u) {
    final user = ref.watch(userProfileProvider);
    final broadcasterId = u.uid ?? '';
    final broadcasterName = u.displayName ?? '主播';
    final broadcasterImage = '${user?.cdnUrl}${u.photoURL.first}';

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

  Widget _buildTopMedia(List<String> avatars) {
    final photos = avatars.where((e) => e.trim().isNotEmpty).toList(); // 再保險

    Widget _img(String url) {
      if (url.startsWith('assets/')) {
        return Image.asset(url, fit: BoxFit.cover);
      }
      return CachedNetworkImage(imageUrl: url, fit: BoxFit.cover);
    }

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
        child: _img(photos.first),
      );
    }

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
          itemBuilder: (_, i, __) => _img(photos[i]),
        ),
        if (photos.length > 1)
          Positioned(
            bottom: 12,
            child: ValueListenableBuilder<int>(
              valueListenable: _currentIndexNotifier,
              builder: (context, currentIndex, _) => AnimatedSmoothIndicator(
                activeIndex: currentIndex,
                count: photos.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: Colors.white,
                  dotColor: Colors.white54,
                  dotHeight: 8, dotWidth: 8, spacing: 6,
                ),
                onDotClicked: (index) => _carouselController.animateToPage(index),
              ),
            ),
          ),
      ],
    );
  }

  Widget buildMyVideoTab(UserModel u , bool effectiveIsLike) {
    final feed = ref.watch(memberFeedByUserProvider(widget.userId));
    final myCdnBase = ref.watch(userProfileProvider)?.cdnUrl ?? '';
    final t = S.of(context);
    // ✅ 下拉重刷
    Widget bodyByState() {
      // 初次載入中
      if (feed.items.isEmpty && feed.isLoading) {
        return const Center(
            child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: CircularProgressIndicator(),
        ));
      }

      // 空狀態
      if (feed.items.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library_outlined,
                    size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text(t.emptyNoContent, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        );
      }

      // 有資料 ➜ 網格 + 底部按鈕
      return CustomScrollView(
        controller: _feedScroll,
        cacheExtent: 3000,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 9 / 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = feed.items[index];
                  final isVideo = item.isVideo;
                  final cover = item.coverUrl;
                  final title = (item.title.isNotEmpty ? item.title : ' ');

                  // ↓ 你的 media 建構邏輯原封不動（略） ↓
                  Widget media;
                  if (!isVideo && cover != null && cover.isNotEmpty) {
                    media = ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: cover,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _fallbackBox(),
                        placeholder: (_, __) => _loadingBox(),
                      ),
                    );
                  } else if (isVideo) {
                    media = ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FutureBuilder<Uint8List?>(
                        future: _getNetworkVideoThumbnail(item.videoUrl),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.done &&
                              snap.data != null) {
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(snap.data!, fit: BoxFit.cover),
                                const Center(
                                    child: Icon(Icons.play_circle_fill,
                                        size: 36, color: Colors.white)),
                              ],
                            );
                          }
                          return _loadingBox();
                        },
                      ),
                    );
                  } else {
                    media = ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _fallbackBox());
                  }

                  final avatarUrl = u.avatarUrl.startsWith('http') ? u.avatarUrl : '$myCdnBase${u.avatarUrl}';

                  return GestureDetector(
                    onTap: () {
                      if (isVideo) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ViewOtherVideoPage(
                              videoPath: item.videoUrl,
                              displayName: u.displayName,
                              avatarPath: avatarUrl,
                              isVip: u.isVip,
                              isLike: u.isLike == 1,
                              message: item.title,
                              uid: u.uid,
                              isBroadcaster: u.isBroadcaster,
                              isTop: item.isTop,
                            ),
                          ),
                        );
                      } else {
                        final imgPath = cover ?? '';
                        if (imgPath.isEmpty) return;
                        final avatarUrl = u.avatarUrl.startsWith('http') ? u.avatarUrl : '$myCdnBase${u.avatarUrl}';

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ViewOtherImagePage(
                              imagePath: imgPath,
                              displayName: u.displayName,
                              avatarPath: avatarUrl,
                              isVip: u.isVip,
                              isLike: u.isLike == 1,
                              message: item.title,
                              uid: u.uid,
                              isBroadcaster: u.isBroadcaster,
                              isTop: item.isTop,
                            ),
                          ),
                        );
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Positioned.fill(child: media),
                              if (item.isTop == 1)
                                Positioned(
                                  bottom: 6,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: Colors.pink,
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Text(t.categoryFeatured,
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 10)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
                childCount: feed.items.length, // ← 不要再 +1 了
              ),
            ),
          ),

          // 底部 loading（有更多時顯示 spinner）
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: (feed.isLoading && feed.hasMore)
                    ? const SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator())
                    : const SizedBox.shrink(),
              ),
            ),
          ),

          SliverToBoxAdapter(child: buildButtonView(u, effectiveIsLike)),
          const SliverToBoxAdapter(child: SizedBox(height: 36)),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(memberFeedByUserProvider(widget.userId).notifier)
            .loadFirstPage(widget.userId);
      },
      child: bodyByState(),
    );
  }

  Widget _buildFeaturedStripIfNeeded(UserModel? u) {
    if (u?.isBroadcaster != true) return const SizedBox.shrink();

    // 撈這位用戶的動態列表，挑 isTop == 1
    final feed = ref.watch(memberFeedByUserProvider(widget.userId));
    final featured = feed.items.where((e) => e.isTop == 1).toList();
    if (featured.isEmpty) return const SizedBox.shrink();

    final cdnBase = ref.watch(userProfileProvider)?.cdnUrl ?? '';

    Widget _thumbOf(MemberVideoModel it) {
      // 120×140 的卡片內容（有影片就取縮圖、否則顯示封面）
      final rounded = BorderRadius.circular(8);

      if (it.isVideo) {
        final videoUrl = _cdnJoin(cdnBase, it.videoUrl);
        return ClipRRect(
          borderRadius: rounded,
          child: FutureBuilder<Uint8List?>(
            future: _getNetworkVideoThumbnail(videoUrl),
            builder: (context, snap) {
              final child = (snap.connectionState == ConnectionState.done && snap.data != null)
                  ? Image.memory(snap.data!, fit: BoxFit.cover)
                  : _loadingBox();
              return Stack(
                fit: StackFit.expand,
                children: [
                  child,
                  const Center(child: Icon(Icons.play_circle_fill, size: 32, color: Colors.white)),
                ],
              );
            },
          ),
        );
      } else {
        final cover = (it.coverUrl ?? '').trim();
        final coverAbs = _cdnJoin(cdnBase, cover);
        return ClipRRect(
          borderRadius: rounded,
          child: (coverAbs.isEmpty)
              ? _fallbackBox()
              : CachedNetworkImage(
            imageUrl: coverAbs,
            fit: BoxFit.cover,
            placeholder: (_, __) => _loadingBox(),
            errorWidget: (_, __, ___) => _fallbackBox(),
          ),
        );
      }
    }

    void _open(MemberVideoModel it) {
      final avatarUrl = u!.avatarUrl.startsWith('http')
          ? u.avatarUrl
          : _cdnJoin(cdnBase, u.avatarUrl);

      if (it.isVideo) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewOtherVideoPage(
              videoPath: _cdnJoin(cdnBase, it.videoUrl),
              displayName: u.displayName,
              avatarPath: avatarUrl,
              isVip: u.isVip,
              isLike: u.isLike == 1,
              message: it.title,
              uid: u.uid,
              isBroadcaster: u.isBroadcaster,
              isTop: it.isTop,
            ),
          ),
        );
      } else {
        final imgPath = _cdnJoin(cdnBase, it.coverUrl ?? '');
        if (imgPath.isEmpty) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewOtherImagePage(
              imagePath: imgPath,
              displayName: u.displayName,
              avatarPath: avatarUrl,
              isVip: u.isVip,
              isLike: u.isLike == 1,
              message: it.title,
              uid: u.uid,
              isBroadcaster: u.isBroadcaster,
              isTop: it.isTop,
            ),
          ),
        );
      }
    }

    final t = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(t.badgeFeatured, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: featured.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10), // 卡片間距 10
            itemBuilder: (_, i) {
              final it = featured[i];
              return GestureDetector(
                onTap: () => _open(it),
                child: SizedBox(
                  width: 120,   // 指定寬度 120
                  height: 140,  // 指定高度 140
                  child: _thumbOf(it),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

// 小工具：loading / fallback
  Widget _loadingBox() => Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );

  Widget _fallbackBox() => Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image_not_supported_outlined)),
      );

  @override
  Widget build(BuildContext context) {
    final asyncUser = ref.watch(otherUserProvider(widget.userId));
    final myCdnBase = ref.watch(userProfileProvider)?.cdnUrl ?? '';

    // 從首頁推薦列表抓「此人」最新的 like 狀態（null 表示列表還沒載到這人）
    final likeFromHome = ref.watch(
      homeFeedProvider.select((s) {
        final hit = s.items.cast<FeedItem?>().firstWhere(
              (e) => e != null && e.uid == widget.userId,
          orElse: () => null,
        );
        if (hit == null) return null;
        return hit.isLike == 1;
      }),
    );

    final t = S.of(context);
    return asyncUser.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(t.loadFailedWith('$e'))),
      ),
      data: (u) {
        final current = u; // ← 用覆寫版
        final displayName = (current.displayName?.isNotEmpty == true)
            ? current.displayName!
            : t.userGeneric;
        final rawPhotos = current.photoURL;
        final headerPhotos = rawPhotos
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)                                     // 先丟掉 ""、"   "
            .map((p) => p.startsWith('http') || p.startsWith('assets/')
            ? p
            : _cdnJoin(myCdnBase, p))                                    // 相對路徑補上 cdn
            .where((p) => p.trim().isNotEmpty)                               // _cdnJoin 遇到空的再丟一次
            .toList();

        if (headerPhotos.isEmpty) {
          headerPhotos.add('assets/pic_girl1.png');                          // 全空時給預設圖
        }
        final likesDisplay = current.fans ?? 0;
        final effectiveIsLike = likeFromHome ?? (u.isLike == 1);

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const BackButton(color: Colors.black38),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 頂部媒體（自動判斷 0/1/多張）
                _buildTopMedia(headerPhotos),
                const SizedBox(height: 8),

                // 基本資訊列（用 displayName / avatarPath）
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: // 放在 build() 裡原來的位置，替換那段 Column
                        Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左側：名字 + 性別年齡 + VIP
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Row(
                              children: [
                                // 名字
                                Flexible(
                                  child: Text(
                                    displayName,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),

                                // 性別年齡 Chip（男藍/女粉）
                                _GenderAgeChip(
                                  sex: u.sex, // 1=男、2=女（若後端不同，自己對應）
                                  age: u.extra?['age']?.toString(),
                                ),
                                const SizedBox(width: 6),

                                // VIP 鑽石（在性別年齡的右邊）
                                if (u.isVip == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 1),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFFFFA770),
                                          Color(0xFFD247FE)
                                        ],
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SvgPicture.asset('assets/pic_vip.svg',
                                            width: 14, height: 14),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'VIP',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // 右側：喜歡數，用自訂圖示
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F0F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset('assets/pic_profile.svg',
                                    width: 16, height: 16),
                                const SizedBox(width: 4),
                                Text(t.likesCount(likesDisplay), style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  child: TabBar(
                    labelColor: const Color(0xFFFF4D67),
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(fontSize: 16),
                    indicatorColor: const Color(0xFFFF4D67),
                    indicatorWeight: 2,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(text: t.tabMyInfo),
                      Tab(text: t.tabPersonalFeed),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      buildMyProfileTab(current, effectiveIsLike), // ✅ 傳入 u
                      buildMyVideoTab(current, effectiveIsLike), // ✅ 傳入 u
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _partnerName(UserModel user) {
    final t = S.of(context);
    // 先用後端給的暱稱，沒有就 fallback
    if ((user.displayName ?? '').isNotEmpty) return user.displayName!;
    return '${t.userGeneric} ${user.uid}';
  }

  // ✅ 安全版：已是絕對網址就直接回傳，避免「重複加前綴」造成 403
  String _cdnJoin(String? base, String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('assets/')) {
      return path; // ← 關鍵
    }
    final b = (base ?? '').replaceAll(RegExp(r'/+$'), '');
    final p = path.replaceAll(RegExp(r'^/+'), '');
    return '$b/$p';
  }

  @override
  void dispose() {
    _feedScroll.dispose();
    _currentIndexNotifier.dispose();
    scaleNotifier.dispose();
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(color: Colors.grey, fontSize: 14);
    const valueStyle = TextStyle(color: Colors.black, fontSize: 14);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 標籤：不撐開，太長就截斷
          Flexible(
            flex: 0,
            child: Text(
              '$label：',
              style: labelStyle,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          Expanded(
            child: Text(
              (value.isEmpty ? '—' : value),
              style: valueStyle,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
      child:
          Text(label, style: const TextStyle(color: Colors.pink, fontSize: 13)),
    );
  }
}

class _GenderAgeChip extends StatelessWidget {
  final dynamic sex; // 後端可能 int 或 String
  final String? age;

  const _GenderAgeChip({required this.sex, this.age});

  @override
  Widget build(BuildContext context) {
    final s = sex?.toString();
    final isMale = s == '1' || s?.toLowerCase() == 'male';
    final isFemale = s == '2' || s?.toLowerCase() == 'female';

    if (!(isMale || isFemale)) return const SizedBox.shrink();

    final color = isMale ? const Color(0xFF3A9EFF) : const Color(0xFFFF4081);
    final icon = isMale ? Icons.male : Icons.female;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            age?.isNotEmpty == true ? age! : '--',
            style: TextStyle(
                fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
