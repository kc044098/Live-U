// # 第二個頁籤內容
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';

class AbilityPage extends StatelessWidget {
  const AbilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(S.of(context).ability));
  }
}
