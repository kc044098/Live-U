import 'dart:async';

import 'package:djs_live_stream/features/auth/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BootGate extends ConsumerStatefulWidget {
  const BootGate({super.key});
  @override
  ConsumerState<BootGate> createState() => _BootGateState();
}

class _BootGateState extends ConsumerState<BootGate> {
  bool _ran = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _ran) return;
      _ran = true;
      // 傳 ref.read，不要傳 ref / 也不要 cast
      unawaited(AuthService(ref.read).routeOnLaunch(context));
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: SizedBox.shrink());
}
