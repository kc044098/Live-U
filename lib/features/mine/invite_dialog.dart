import 'dart:io';
import 'dart:ui' as ui;

import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';

class InviteDialog extends ConsumerStatefulWidget {
  const InviteDialog({super.key});

  @override
  ConsumerState<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<InviteDialog> {
  final GlobalKey _qrKey = GlobalKey(); // 用來截圖 QR 區塊

  String? _inviteUrl;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInviteUrl();
  }

  Future<void> _loadInviteUrl() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url = await ref.read(userRepositoryProvider).fetchInviteUrl();
      if (!mounted) return;
      setState(() {
        _inviteUrl = url;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
      Fluttertoast.showToast(msg: S.of(context).inviteGetLinkFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 背景 + 內文
          Container(
            width: double.infinity,
            height: 500,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: Stack(
              children: [
                SvgPicture.asset(
                  'assets/bg_invite_dialog.svg',
                  width: double.infinity,
                  fit: BoxFit.fill,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      Text(s.inviteScanQrTitle,
                          style: const TextStyle(fontSize: 16, color: Colors.black)),
                      const SizedBox(height: 8),
                      Text(s.inviteScanQrSubtitle,
                          style: const TextStyle(fontSize: 18, color: Color(0xFFFB5D5D))),
                      const SizedBox(height: 16),

                      // 白色 QR 區塊（載入中/錯誤時有對應 UI）
                      Center(
                        child: Container(
                          width: 268,
                          height: 268,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(child: _buildQrArea()),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // 底部三個動作：分享、複製、保存
                      Material(
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  _ActionItem(
                                    iconAsset: 'assets/icon_share.svg',
                                    label: s.inviteSharePoster,
                                    enabled: (_inviteUrl ?? '').isNotEmpty,
                                    onTap: (_inviteUrl ?? '').isEmpty ? null : () => _showShareBottomSheet(context),
                                  ),
                                  Container(width: 1, height: 20, color: const Color(0xFFFACCCC)),
                                  _ActionItem(
                                    iconAsset: 'assets/icon_copy.svg',
                                    label: s.inviteCopyLink,
                                    enabled: (_inviteUrl ?? '').isNotEmpty,
                                    onTap: (_inviteUrl ?? '').isEmpty ? null : () {
                                      Clipboard.setData(ClipboardData(text: _inviteUrl!));
                                      Fluttertoast.showToast(msg: s.inviteCopied);
                                    },
                                  ),
                                  Container(width: 1, height: 20, color: const Color(0xFFFACCCC)),
                                  _ActionItem(
                                    iconAsset: 'assets/icon_save.svg',
                                    label: s.inviteSaveImage,
                                    enabled: (_inviteUrl ?? '').isNotEmpty,
                                    onTap: (_inviteUrl ?? '').isEmpty ? null : () => _saveQrCode(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 48,
            right: 30,
            child: Image.asset(
              'assets/message_like_2.png',
              width: 60,
              height: 60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrArea() {
    final s = S.of(context);
    if (_loading) {
      return const SizedBox(
        width: 268,
        height: 268,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SizedBox(
        width: 268,
        height: 268,
        child: Center(
          child: Text(s.inviteLoadFailed, style: TextStyle(color: Colors.red[400])),
        ),
      );
    }
    if ((_inviteUrl ?? '').isEmpty) {
      return SizedBox(
        width: 268,
        height: 268,
        child: Center(child: Text(s.inviteInvalidLink)),
      );
    }

    return RepaintBoundary(
      key: _qrKey,
      child: Container(
        width: 268,
        height: 268,
        decoration: BoxDecoration(
          color: Colors.white,       // 截圖白底
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: QrImageView(
          data: _inviteUrl!,
          version: QrVersions.auto,
          size: 250,
          backgroundColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> _saveQrCode(BuildContext context) async {
    final s = S.of(context);
    try {
      final ok = await _ensureSavePermission(context);
      if (!ok) return;

      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Fluttertoast.showToast(msg: s.inviteSavingNotReady);
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = Directory('/storage/emulated/0/Pictures/lu.live');
      await directory.create(recursive: true);
      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/qr_$timeStamp.png');
      await file.writeAsBytes(pngBytes);

      await OpenFile.open(file.path);
      Fluttertoast.showToast(msg: s.inviteSavedToAlbum);
    } catch (e) {
      debugPrint("❌ 錯誤: $e");
      Fluttertoast.showToast(msg: s.inviteSaveFailed);
    }
  }

  Future<bool> _ensureSavePermission(BuildContext context) async {
    final results = await [
      if (Platform.isAndroid) Permission.photos,       // Android 13+
      if (Platform.isAndroid) Permission.storage,      // Android 12-
      if (Platform.isIOS)     Permission.photosAddOnly // iOS 只寫入相簿
    ].request();

    final granted = results.values.any((s) => s.isGranted);
    if (granted) return true;

    final permanentlyDenied = results.values.any((s) => s.isPermanentlyDenied);
    if (permanentlyDenied) {
      final go = await _showOpenSettingsDialog(context);
      if (go == true) {
        await openAppSettings();
        final re = await [
          if (Platform.isAndroid) Permission.photos,
          if (Platform.isAndroid) Permission.storage,
          if (Platform.isIOS)     Permission.photosAddOnly
        ].request();
        return re.values.any((s) => s.isGranted);
      }
    }
    return false;
  }

  Future<bool?> _showOpenSettingsDialog(BuildContext context) {
    final s = S.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.commonPermissionDisabled),
        content: Text(s.commonPermissionRationaleOpenSettings),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: Text(s.commonGoToSettings)),
        ],
      ),
    );
  }

  void _showShareBottomSheet(BuildContext context) {
    final s = S.of(context);
    if ((_inviteUrl ?? '').isEmpty) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.shareTo, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareIcon(context, 'facebook', 'Facebook', 'assets/icon_fb.png', _shareToFacebook),
                  _buildShareIcon(context, 'twitter', 'Twitter', 'assets/icon_twitter.png', _shareToTwitter),
                  _buildShareIcon(context, 'whatsapp', 'WhatsApp', 'assets/icon_whatsapp.png', _shareToWhatsApp),
                  _buildShareIcon(context, 'messenger', 'Messenger', 'assets/icon_messenger.png', _shareToMessenger),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareIcon(
      BuildContext context, String name, String label, String assetPath, VoidCallback onTap) {
    final disabled = (_inviteUrl ?? '').isEmpty;
    return GestureDetector(
      onTap: disabled ? null : () {
        Navigator.pop(context);
        onTap();
      },
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: Column(
          children: [
            Image.asset(assetPath, width: 40, height: 40),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // ——— 分享渠道（將動態 URL 帶入） ———

  void _shareToFacebook() {
    if ((_inviteUrl ?? '').isEmpty) return;
    final url = 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(_inviteUrl!)}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _shareToTwitter() {
    if ((_inviteUrl ?? '').isEmpty) return;
    final url = 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(_inviteUrl!)}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _shareToWhatsApp() {
    if ((_inviteUrl ?? '').isEmpty) return;
    final url = 'https://wa.me/?text=${Uri.encodeComponent(_inviteUrl!)}';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _shareToMessenger() async {
    final link = _inviteUrl;
    if (Platform.isIOS) {
      await shareToMessengerIOS(link);
    } else {
      await shareToMessengerAndroid(link);
    }
  }

  Future<void> shareToMessengerAndroid(String? inviteUrl) async {
    final s = S.of(context);
    final url = _inviteUrl ?? '';
    if (url.isEmpty) return;

    final uri = Uri.parse('fb-messenger://share?link=${Uri.encodeComponent(url)}');

    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        Fluttertoast.showToast(msg: s.messengerNotInstalled);
      }
    } else {
      Fluttertoast.showToast(msg: s.messengerNotInstalled);
    }
  }

  Future<void> shareToMessengerIOS(String? inviteUrl) async {
    final s = S.of(context);
    final link = inviteUrl ?? '';
    if (link.isEmpty) return;

    final uri = Uri.parse('fb-messenger://share?link=${Uri.encodeComponent(link)}');

    try {
      final can = await canLaunchUrl(uri);
      if (can) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok) {
          Fluttertoast.showToast(msg: s.messengerNotInstalled);
        }
        return;
      }
      Fluttertoast.showToast(msg: s.messengerNotInstalled);
    } catch (_) {
      Fluttertoast.showToast(msg: s.messengerNotInstalled);
    }
  }
}
class _ActionItem extends StatelessWidget {
  final String iconAsset;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;
  const _ActionItem({
    required this.iconAsset,
    required this.label,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xFFFB5D5D) : Colors.grey;
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Center(
          // 關鍵：縮小以避免超寬
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(iconAsset, width: 18, height: 18, color: color),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 12, color: color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
