import 'package:flutter/material.dart';

import '../features/call/incoming_call_banner.dart';
import '../features/message/inbox_message_banner.dart';
import '../globals.dart';

class BannerService {
  BannerService._();
  static final BannerService I = BannerService._();

  OverlayEntry? _entry;

  BuildContext? get _overlayContext =>
      rootNavigatorKey.currentState?.overlay?.context;

  void dismiss() {
    _entry?.remove();
    _entry = null;
  }

  void showIncoming({
    required String callerName,
    required String avatarUrl,
    required int flag, // 1=video, 2=voice
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    dismiss();
    final ctx = _overlayContext;
    if (ctx == null) return;

    _entry = OverlayEntry(
      builder: (_) => IncomingCallBanner(
        callerName: callerName,
        avatarUrl: avatarUrl,
        flag: flag,
        onAccept: () {
          dismiss();
          onAccept();
        },
        onReject: () {
          dismiss();
          onReject();
        },
      ),
    );
    rootNavigatorKey.currentState!.overlay!.insert(_entry!);
  }

  void showInbox({
    required String title,
    required String avatarUrl,
    required VoidCallback onReply,
    String? preview,
    String? previewContent,
    String? cdnBase,
  }) {
    dismiss();
    final ctx = _overlayContext;
    if (ctx == null) return;

    _entry = OverlayEntry(
      builder: (_) => InboxMessageBanner(
        title: title,
        avatarUrl: avatarUrl,
        onReply: () {
          dismiss();
          onReply();
        },
        preview: preview,
        previewContent: previewContent,
        cdnBase: cdnBase,
      ),
    );
    rootNavigatorKey.currentState!.overlay!.insert(_entry!);
  }
}