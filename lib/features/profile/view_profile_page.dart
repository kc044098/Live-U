// 檢視其他人的個人資料
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../call/call_request_page.dart';
import '../message/message_chat_page.dart';
import '../widgets/view_other_image_page.dart';
import '../widgets/view_other_video_page.dart';

class ViewProfilePage extends StatefulWidget {
  final String displayName;
  final String avatarPath;

  const ViewProfilePage({super.key, required this.displayName, required this.avatarPath});

  @override
  State<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {

  final CarouselSliderController _carouselController = CarouselSliderController();
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier(0);

  final ValueNotifier<bool> isLikedNotifier = ValueNotifier(false);
  final ValueNotifier<double> scaleNotifier = ValueNotifier(1.0);

  final List<String> demoImages = [
    'assets/pic_girl1.png',
    'assets/pic_girl2.png',
    'assets/pic_girl3.png',
  ];

  Future<Uint8List?> _getVideoThumbnail(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_video.mp4');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      final thumbnail = await VideoThumbnail.thumbnailData(
        video: tempFile.path,
        imageFormat: ImageFormat.PNG,
        maxWidth: 128,
        quality: 75,
      );
      return thumbnail;
    } catch (e) {
      debugPrint("\uD83C\uDFAC Failed to generate video thumbnail: $e");
      return null;
    }
  }

  Widget _buildMediaCard({String? imagePath, String? videoPath}) {
    return SizedBox(
      width: 100,
      height: 120,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imagePath != null
                ? Image.asset(imagePath, width: 100, height: 140, fit: BoxFit.cover)
                : videoPath != null
                ? FutureBuilder<Uint8List?>(
              future: _getVideoThumbnail(videoPath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  return Image.memory(snapshot.data!, width: 100, height: 140, fit: BoxFit.cover);
                } else {
                  return Container(
                    width: 100,
                    height: 140,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
              },
            )
                : const SizedBox.shrink(),
          ),
          if (videoPath != null)
            const Positioned.fill(
              child: Center(
                child: Icon(Icons.play_circle_fill, size: 36, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildMyProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('精选', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewOtherImagePage(imagePath: 'assets/pic_girl2.png', displayName: widget.displayName, avatarPath: widget.avatarPath),
                    ),
                  );
                },
                child: _buildMediaCard(imagePath: 'assets/pic_girl2.png'),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewOtherImagePage(imagePath: 'assets/pic_girl3.png', displayName: widget.displayName, avatarPath: widget.avatarPath),
                    ),
                  );
                },
                child: _buildMediaCard(imagePath: 'assets/pic_girl3.png'),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewOtherVideoPage(videoPath: 'assets/demo_video1.mp4', displayName: widget.displayName, avatarPath: widget.avatarPath),
                    ),
                  );
                },
                child: _buildMediaCard(videoPath: 'assets/demo_video1.mp4'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('关于我', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  children: const [
                    Expanded(child: _InfoRow(label: '身高', value: '155cm')),
                    Expanded(child: _InfoRow(label: '体重', value: '100磅')),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: const [
                    Expanded(child: _InfoRow(label: '三围', value: '90–60–70')),
                    Expanded(child: _InfoRow(label: '城市', value: '武汉')),
                  ],
                ),
                SizedBox(height: 4),
                const Row(
                  children: [
                    Expanded(child: _InfoRow(label: '工作', value: '人事')),
                    Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('我的标签', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _TagChip(label: '#吃货'),
              _TagChip(label: '#实在'),
              _TagChip(label: '#气质'),
              _TagChip(label: '#幽默风趣'),
              _TagChip(label: '#独立'),
              _TagChip(label: '#宠物'),
              _TagChip(label: '#安静'),
              _TagChip(label: '#气质'),
              _TagChip(label: '#小女人'),
            ],
          ),
          const SizedBox(height: 16),
          const Text('我的礼物', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(13, (index) {
              return _GiftItem(
                imagePath: 'assets/gift1.png',
                label: '礼物${index + 1}',
              );
            }),
          ),
          const SizedBox(height: 24),
          buildButtonView(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget buildMyVedioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // 禁止 GridView 滾動
            itemCount: 12,
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 9 / 12,
            ),
            itemBuilder: (context, index) {
              final isVideo = index % 3 == 0;
              final path = isVideo
                  ? 'assets/demo_video1.mp4'
                  : (index % 2 == 0
                  ? 'assets/pic_girl2.png'
                  : 'assets/pic_girl3.png');

              return GestureDetector(
                onTap: () {
                  if (isVideo) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewOtherVideoPage(videoPath: path, displayName: widget.displayName, avatarPath: widget.avatarPath),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewOtherImagePage(imagePath: path, displayName: widget.displayName, avatarPath: widget.avatarPath),
                      ),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 220,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: isVideo
                                ? FutureBuilder<Uint8List?>(
                              future: _getVideoThumbnail(path),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.done &&
                                    snapshot.hasData) {
                                  return Image.memory(snapshot.data!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover);
                                } else {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                }
                              },
                            )
                                : Image.asset(
                              path,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (isVideo)
                            const Positioned.fill(
                              child: Center(
                                child: Icon(Icons.play_circle_fill,
                                    size: 36, color: Colors.white),
                              ),
                            ),
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.pink,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('精选',
                                  style: TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                          ),
                          const Positioned(
                            bottom: 6,
                            right: 6,
                            child: Row(
                              children: [
                                Icon(Icons.visibility, color: Colors.white, size: 14),
                                SizedBox(width: 2),
                                Text('1.1K',
                                    style: TextStyle(color: Colors.white, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('别看文案，看我啦…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          // 發布按鈕
          buildButtonView(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget buildButtonView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: isLikedNotifier,
              builder: (_, isLiked, __) {
                return ValueListenableBuilder<double>(
                  valueListenable: scaleNotifier,
                  builder: (_, scale, __) {
                    return GestureDetector(
                      onTap: _onLikePressed,
                      child: AnimatedScale(
                        scale: scale,
                        duration: const Duration(milliseconds: 150),
                        child: SvgPicture.asset(
                          isLiked
                              ? 'assets/live_heart_filled.svg'
                              : 'assets/live_heart2.svg',
                          width: 40,
                          height: 40,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 2),
          ],
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.pink),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessageChatPage(
                  partnerName: widget.displayName,
                  partnerAvatar: widget.avatarPath,
                  isVip: true, // 假設全部是 VIP，用條件決定也可
                  statusText: '當前在線', // 可依需要傳不同文字
                ),
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Text('私信TA', style: TextStyle(color: Colors.pink)),
          ),
        ),
        Column(
          children: [
            GestureDetector(
              onTap: () {
                _handleCallRequest();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB56B), Color(0xFFDF65F8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text('发起视频', style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ),
            const SizedBox(height: 4),
            const Text('1美元/分钟', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  void _onLikePressed() {
    isLikedNotifier.value = !isLikedNotifier.value;
    scaleNotifier.value = 3.0; // 放大

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        scaleNotifier.value = 1.0; // 縮回
      }
    });
  }

  void _handleCallRequest() {
    final broadcasterId = widget.displayName ?? '';
    final broadcasterName = widget.displayName ?? '主播';
    final broadcasterImage = widget.avatarPath ?? 'assets/default.jpg';

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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CarouselSlider.builder(
                  carouselController: _carouselController,
                  itemCount: demoImages.length,
                  options: CarouselOptions(
                    height: 240,
                    viewportFraction: 1.0,
                    autoPlay: true,
                    onPageChanged: (index, reason) {
                      _currentIndexNotifier.value = index;
                    },
                  ),
                  itemBuilder: (context, index, realIndex) {
                    return Image.asset(
                      demoImages[index],
                      width: double.infinity,
                      height: 240,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    );
                  },
                ),
                Positioned(
                  bottom: 12,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _currentIndexNotifier,
                    builder: (context, currentIndex, _) {
                      return AnimatedSmoothIndicator(
                        activeIndex: currentIndex,
                        count: demoImages.length,
                        effect: const ExpandingDotsEffect(
                          activeDotColor: Colors.white,
                          dotColor: Colors.white54,
                          dotHeight: 8,
                          dotWidth: 8,
                          spacing: 6,
                        ),
                        onDotClicked: (index) =>
                            _carouselController.animateToPage(index),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.displayName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              gradient: const LinearGradient(colors: [Color(0xFFFF8FB1), Color(0xFF9F6EFF)]),
                            ),
                            child: const Text('VIP', style: TextStyle(fontSize: 10, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF4081),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.female, size: 14, color: Colors.white),
                            SizedBox(width: 2),
                            Text('19', style: TextStyle(fontSize: 12, color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('11喜欢', style: TextStyle(fontSize: 12, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: TabBar(
                labelColor: Colors.pink,
                unselectedLabelColor: Colors.grey,
                labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                unselectedLabelStyle: TextStyle(fontSize: 16),
                indicatorColor: Colors.pink,
                indicatorWeight: 2,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: '我的资料'),
                  Tab(text: '个人动态'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  buildMyProfileTab(),
                  buildMyVedioTab(),
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
    isLikedNotifier.dispose();
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Text('$label：', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 4),
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

class _GiftItem extends StatelessWidget {
  final String imagePath;
  final String label;

  const _GiftItem({required this.imagePath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(imagePath, width: 60, height: 60),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
