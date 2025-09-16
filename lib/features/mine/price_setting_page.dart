import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../profile/profile_controller.dart';

class PriceSettingPage extends ConsumerStatefulWidget {
  const PriceSettingPage({super.key});
  @override
  ConsumerState<PriceSettingPage> createState() => _PriceSettingPageState();
}

class _PriceSettingPageState extends ConsumerState<PriceSettingPage> {

  static const int kMinPrice = 100;
  static const int kMaxPrice = 1000;

  int _videoPrice = 100;
  int _voicePrice = 100;

  bool _savingVideo = false;
  bool _savingVoice = false;

  bool _silentBusy = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('价格设置', style: TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // _buildMergedCallToggle(isVideo),

          _buildItem(
            iconPath: 'assets/icon_set_price_2.svg',
            label: '视频价格设置',
            trailing: _buildPriceButton(
              amount: _videoPrice,               // ★ 新增
              onPressed: _savingVideo ? null : () => _showEditPriceDialog(
                title: '视频价格设置',
                initial: _videoPrice,
                onSaved: (v) => _applyPrice(isVideo: true, value: v),  // ★ 呼叫 API
              ),
            ),
          ),

          _buildItem(
            iconPath: 'assets/icon_set_price_4.svg',
            label: '语音价格设置',
            trailing: _buildPriceButton(
              amount: _voicePrice,                  // ★ 新增
              onPressed: _savingVoice ? null : () => _showEditPriceDialog(
                title: '语音价格设置',
                initial: _voicePrice,
                onSaved: (v) => _applyPrice(isVideo: false, value: v), // ★ 呼叫 API
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceButton({
    required int amount,
    required VoidCallback? onPressed,
    bool loading = false,                 // ★ 新增
  }) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,   // ★ 儲存中禁用
        style: ElevatedButton.styleFrom(
          elevation: 1,
          shadowColor: Colors.black26,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size(130, 10),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading) ...[
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
            ] else ...[
              Image.asset('assets/icon_gold1.png', width: 18, height: 18),
              const SizedBox(width: 6),
            ],
            Text(
              '$amount币 / 分钟',
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  /// 合併開關（開: 視頻；關: 語音）
  Widget _buildMergedCallToggle(bool isVideo) {
    final String iconPath = 'assets/icon_set_price_1.svg';

    final String mainLabel = '视频接听';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SvgPicture.asset(iconPath, width: 24, height: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  mainLabel,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              CupertinoSwitch(
                value: isVideo,
                onChanged: (value) {
                  final u = ref.read(userProfileProvider);
                  if (u == null) return;
                  ref.read(userProfileProvider.notifier).state =
                      u.copyWith(isVideoCall: value);
                },
                activeColor: Colors.pinkAccent,
                trackColor: const Color(0xFFEDEDED),
              ),
            ],
          ),
        ),

        // 🔹 底下提示條
        Container(
          width: double.infinity,
          color: const Color(0xFFFFE4E4), // 淡粉底
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Text(
            '如果关闭视频接听，则默认为语音接听。开启则优先视频接听',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem({
    required String iconPath,
    required String label,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SvgPicture.asset(iconPath, width: 24, height: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          trailing,
        ],
      ),
    );
  }

  /// 彈窗：左邊「請輸入價格」，右邊數字輸入框，按保存更新價格
  Future<void> _showEditPriceDialog({
    required String title,
    required int initial,
    required ValueChanged<int> onSaved,
  }) async {
    final controller = TextEditingController(text: initial.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
          content: SizedBox(
            width: 300,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4), // 最高 1000
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      hintText: '請輸入 100 ~ 1000',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                final v = int.tryParse(text);

                if (v == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('請輸入有效數字')),
                  );
                  return;
                }
                if (v < 100 || v > 1000) {
                  Fluttertoast.showToast(msg: '價格需介於 $kMinPrice ~ $kMaxPrice');
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );

    if (result != null) onSaved(result);
  }

  Future<void> _applyPrice({
    required bool isVideo,
    required int value,
  }) async {
    if (value < kMinPrice || value > kMaxPrice) {
      Fluttertoast.showToast(msg: '價格需介於 $kMinPrice ~ $kMaxPrice');
      return;
    }
    if (_silentBusy) return;         // 防止連點造成重複請求（無 UI 顯示）
    _silentBusy = true;

    final prev = isVideo ? _videoPrice : _voicePrice;

    // 樂觀更新（無 loading）
    setState(() {
      if (isVideo) _videoPrice = value; else _voicePrice = value;
    });

    try {
      await ref.read(userRepositoryProvider)
          .setPrice(isVideo: isVideo, price: value);
      Fluttertoast.showToast(msg: '保存成功');
    } catch (_) {
      // 失敗就還原
      setState(() {
        if (isVideo) _videoPrice = prev; else _voicePrice = prev;
      });
      Fluttertoast.showToast(msg: '保存失敗，請稍後再試');
    } finally {
      _silentBusy = false;
    }
  }
}