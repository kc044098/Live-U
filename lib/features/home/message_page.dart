import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../profile/profile_controller.dart';
import '../../l10n/l10n.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('訊息頁'));
  }
}
