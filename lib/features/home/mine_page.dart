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
    final profile = ref.watch(userProfileProvider);
    final controller = ref.read(userProfileProvider.notifier);
    final l10n = S.of(context);

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
                  controller.updateAvatar(image.path);
                }
              },
              child: CircleAvatar(
                radius: 40,
                backgroundImage: profile.avatarUrl.isNotEmpty
                    ? FileImage(File(profile.avatarUrl))
                    : null,
                child: profile.avatarUrl.isEmpty ? const Icon(Icons.person) : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: profile.name),
              decoration: InputDecoration(labelText: l10n.name),
              onSubmitted: controller.updateName,
            ),
          ],
        ),
      ),
    );
  }
}