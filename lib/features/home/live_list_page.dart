// # 第一個頁籤內容
import 'package:flutter/material.dart';
import '../live/audience_page.dart';
import '../live/live_video_page.dart';

class LiveListPage extends StatelessWidget {
  LiveListPage({super.key});

  final List<Map<String, String>> mockUsers = List.generate(8, (index) {
    final imgIndex = (index % 4) + 1;
    return {
      'broadcaster': 'broadcaster00$index',
      'name': 'Ariana Flores $index',
      'image': 'assets/pic_girl$imgIndex.png',
    };
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '交友',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GridView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: mockUsers.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2欄
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75, // 控制圖片與下方資訊比例
          ),
            itemBuilder: (context, index) {
              final user = mockUsers[index];
              return GestureDetector(
                onTap: () {
                  final userWithVideo = {
                    ...user,
                    'videoPath': 'assets/demo_video.mp4',
                  };
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LiveVideoPage(user: userWithVideo),
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
                        const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.person, size: 14, color: Colors.white),
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
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.orangeAccent,
                              Colors.purpleAccent,
                            ]),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.videocam, size: 14, color: Colors.white),
                        ),
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
