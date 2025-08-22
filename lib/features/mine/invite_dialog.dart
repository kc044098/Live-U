import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteDialog extends StatelessWidget {
  InviteDialog({super.key});

  final String inviteUrl = 'https://api.ludev.shop?inviterId=frankie';
  final GlobalKey _qrKey = GlobalKey(); // 用來截圖 QR 區塊

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 背景 + 內文
          Container(
            width: double.infinity,
            height: 480,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // 背景圖
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
                      const Text(
                        '识别二维码下载',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '即可开启甜蜜交友之旅',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFFFB5D5D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 白色 QR 區塊
                      Center(
                        child: Container(
                          width: 268,
                          height: 268,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Container(
                              width: double.infinity,
                              height: 250,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: RepaintBoundary(
                                  key: _qrKey,
                                  child: QrImageView(
                                    data: inviteUrl,
                                    version: QrVersions.auto,
                                    size: 250,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Material( // 讓 InkWell 有水波（透明也可以）
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              // 分享海報
                              Expanded(
                                child: InkWell(
                                  onTap: () => _showShareBottomSheet(context),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset('assets/icon_share.svg', width: 18, height: 18),
                                      const SizedBox(width: 6),
                                      const Text('分享海報', style: TextStyle(fontSize: 12, color: Color(0xFFFB5D5D))),
                                    ],
                                  ),
                                ),
                              ),

                              // 分隔線
                              Container(width: 1, height: 20, color: const Color(0xFFFACCCC)),

                              // 複製連結
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Clipboard.setData(const ClipboardData(text: 'https://api.ludev.shop?inviterId=frankie'));
                                    Fluttertoast.showToast(msg: "已複製連結");
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset('assets/icon_copy.svg', width: 18, height: 18),
                                      const SizedBox(width: 6),
                                      const Text('複製連接', style: TextStyle(fontSize: 12, color: Color(0xFFFB5D5D))),
                                    ],
                                  ),
                                ),
                              ),

                              // 分隔線
                              Container(width: 1, height: 20, color: const Color(0xFFFACCCC)),

                              // 保存圖片
                              Expanded(
                                child: InkWell(
                                  onTap: () => _saveQrCode(context), // ← 確認有傳 context
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SvgPicture.asset('assets/icon_save.svg', width: 18, height: 18),
                                      const SizedBox(width: 6),
                                      const Text('保存圖片', style: TextStyle(fontSize: 12, color: Color(0xFFFB5D5D))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
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

  Future<void> _saveQrCode(BuildContext context) async {
    try {
      final ok = await _ensureSavePermission(context);
      if (!ok) return;

      final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        Fluttertoast.showToast(msg: "畫面尚未準備完成");
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
      Fluttertoast.showToast(msg: "已保存至相簿資料夾！");
    } catch (e) {
      debugPrint("❌ 錯誤: $e");
      Fluttertoast.showToast(msg: "保存失敗");
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

    // 永久拒絕 → 引導去系統設定
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

  // 只有「去設定」這個引導（非必然出現）
  Future<bool?> _showOpenSettingsDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('權限被停用'),
        content: const Text('您已關閉儲存/相簿權限，請前往系統設定手動開啟。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('去設定')),
        ],
      ),
    );
  }

  void _showShareBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('分享到',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareIcon(context, 'facebook', 'Facebook', 'assets/icon_fb.png',
                      _shareToFacebook),
                  _buildShareIcon(context, 'twitter', 'Twitter',
                      'assets/icon_twitter.png', _shareToTwitter),
                  _buildShareIcon(context, 'whatsapp', 'WhatsApp',
                      'assets/icon_whatsapp.png', _shareToWhatsApp),
                  _buildShareIcon(context, 'instagram', 'Messenger',
                      'assets/icon_messenger.png', _shareToMessenger),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareIcon(BuildContext context, String name, String label, String assetPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Image.asset(assetPath, width: 40, height: 40),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _shareToFacebook() {
    final url = 'https://www.facebook.com/sharer/sharer.php?u=$inviteUrl';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _shareToTwitter() {
    final url = 'https://twitter.com/intent/tweet?text=$inviteUrl';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _shareToWhatsApp() {
    final url = 'https://wa.me/?text=$inviteUrl';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _shareToMessenger() {
    final url = 'fb-messenger://share/?link=$inviteUrl';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
