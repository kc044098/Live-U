// # 第三個頁籤內容

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../profile/profile_controller.dart';
import '../../l10n/l10n.dart';

class MinePage extends ConsumerWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    final controller = ref.read(userProfileProvider.notifier);
    final l10n = S.of(context);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final nameController = TextEditingController(text: user.displayName);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mine)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  controller.updateAvatar(image.path); // 可用路徑當 photoURL（若非 URL）
                }
              },
              child: CircleAvatar(
                radius: 40,
                backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
                    ? (user.photoURL!.startsWith('http')
                    ? NetworkImage(user.photoURL!)
                    : FileImage(File(user.photoURL!)) as ImageProvider)
                    : null,
                child: user.photoURL == null || user.photoURL!.isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.name),
              onSubmitted: (value) {
                controller.updateDisplayName(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
