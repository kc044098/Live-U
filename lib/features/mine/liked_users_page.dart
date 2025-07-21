// 我喜歡的 頁面

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../profile/view_profile_page.dart';

class LikedUsersPage extends StatelessWidget {
  const LikedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> likedUsers = [
      {'name': '漂亮的小姐姐 1', 'image': 'assets/pic_girl1.png'},
      {'name': '漂亮的小姐姐 2', 'image': 'assets/pic_girl2.png'},
      {'name': '漂亮的小姐姐 3', 'image': 'assets/pic_girl3.png'},
      {'name': '漂亮的小姐姐 4', 'image': 'assets/pic_girl4.png'},
      {'name': '漂亮的小姐姐 5', 'image': 'assets/pic_girl5.png'},
      {'name': '漂亮的小姐姐 6', 'image': 'assets/pic_girl6.png'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('我喜欢的', style: TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 60),
        itemCount: likedUsers.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.66,
        ),
        itemBuilder: (context, index) {
          final user = likedUsers[index];
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
            child: _buildLikedCard(user),
          );
        },
      ),
    );
  }

  Widget _buildLikedCard(Map<String, String> user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              user['image']!,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 4),
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
            SvgPicture.asset(
              'assets/logo_placeholder.svg',
              height: 28,
              width: 28,
            ),
          ],
        ),
      ],
    );
  }
}
