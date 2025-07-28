// 個人資料頁面
import 'dart:convert';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../data/models/user_model.dart';
import '../../routes/app_routes.dart';
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
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier(0);

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
      debugPrint("🎬 Failed to generate video thumbnail: $e");
      return null;
    }
  }

  Widget _buildProfileHeader(UserModel? user) {
    final extra = user?.extra ?? {};
    final photos = <String>[];

    for (int i = 1; i <= 3; i++) {
      final key = 'photo$i';
      final base64Image = extra[key];
      if (base64Image != null && base64Image.isNotEmpty) {
        photos.add(base64Image);
      }
    }

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

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider.builder(
          itemCount: photos.length,
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 288,
            viewportFraction: 1.0,
            autoPlay: true,
            onPageChanged: (index, reason) {
              _currentIndexNotifier.value = index;  // 🔹 不用 setState
            },
          ),
          itemBuilder: (context, index, realIndex) {
            try {
              final bytes = base64Decode(photos[index]);
              return Image.memory(
                bytes,
                width: double.infinity,
                height: 288,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              );
            } catch (_) {
              return Image.asset(
                'assets/my_photo_defult.jpeg',
                width: double.infinity,
                height: 288,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              );
            }
          },
        ),
        Positioned(
          bottom: 12,
          child: ValueListenableBuilder<int>(
            valueListenable: _currentIndexNotifier,
            builder: (context, currentIndex, _) {
              return AnimatedSmoothIndicator(
                activeIndex: currentIndex,
                count: photos.length,
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
    );
  }

  Widget buildMyProfileTab(UserModel? user) {
    // 從 user.extra 中讀取擴展資料（假設後端返回了身高、體重等資訊）
    final height = user?.extra?['height'] ?? '未知';
    final weight = user?.extra?['weight'] ?? '未知';
    final body = user?.extra?['body'] ?? '未知';
    final city = user?.extra?['city'] ?? '未知';
    final job = user?.extra?['job'] ?? '未知';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text('關於我', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    Expanded(child: _InfoRow(label: '身高', value: height)),
                    Expanded(child: _InfoRow(label: '體重', value: weight)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _InfoRow(label: '三圍', value: body)),
                    Expanded(child: _InfoRow(label: '城市', value: city)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _InfoRow(label: '工作', value: job)),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('我的標籤', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(label: '#吃貨'),
              _TagChip(label: '#幽默風趣'),
              _TagChip(label: '#大男人'),
              _TagChip(label: '#健美'),
            ],
          ),
          const SizedBox(height: 50),
          Center(
            child: SizedBox(
              width: 280,
              height: 40,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFFF4D67), width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icon_edit.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFFF4D67),
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '編輯',
                      style: TextStyle(
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

  Widget buildMyVedioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 8 / 12,
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
                        builder: (context) =>
                            FullscreenVideoPlayerPage(videoPath: path),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            FullscreenImagePage(imagePath: path),
                      ),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 250,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: isVideo
                                ? FutureBuilder<Uint8List?>(
                              future: _getVideoThumbnail(path),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                    snapshot.hasData) {
                                  return Image.memory(snapshot.data!,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover);
                                } else {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.pink,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('精選',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10)),
                            ),
                          ),
                          const Positioned(
                            bottom: 6,
                            right: 6,
                            child: Row(
                              children: [
                                Icon(Icons.visibility,
                                    color: Colors.white, size: 14),
                                SizedBox(width: 2),
                                Text('1.1K',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('別看文案，看我啦…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.videoRecorder);
              },
              child: Container(
                width: 288,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB56B), Color(0xFFDF65F8)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset('assets/icon_start_video.svg',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 6),
                      const Text('發布動態',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            user?.displayName ?? '個人資料',
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle:true,
          leading: const BackButton(color: Colors.white),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: TabBar(
                labelColor: Color(0xFFFF4D67),
                unselectedLabelColor: Colors.grey,
                labelStyle:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                unselectedLabelStyle: TextStyle(fontSize: 16),
                indicatorColor: Color(0xFFFF4D67),
                indicatorWeight: 2,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: '我的資料'),
                  Tab(text: '個人動態'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  buildMyProfileTab(user),
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
