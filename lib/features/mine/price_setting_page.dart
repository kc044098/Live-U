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

  /// 目前顯示的價格（可從 API 帶入）
  int _videoPrice = 100;
  int _voicePrice = 80;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider);
    final bool isVideo = user?.isVideoCall ?? true;

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
          // 合併後的接聽開關，放在原本「視頻接聽」的位置
          _buildMergedCallToggle(isVideo),

          // 視頻價格設置（右邊改成白底陰影按鈕，點擊可編輯）
          _buildItem(
            iconPath: 'assets/icon_set_price_2.svg',
            label: '视频价格设置',
            trailing: _buildPriceButton(
              amount: _videoPrice,
              onPressed: () => _showEditPriceDialog(
                title: '视频价格设置',
                initial: _videoPrice,
                onSaved: (v) => setState(() => _videoPrice = v),
              ),
            ),
          ),

          // 語音價格設置（右邊改成白底陰影按鈕，點擊可編輯）
          _buildItem(
            iconPath: 'assets/icon_set_price_4.svg',
            label: '语音价格设置',
            trailing: _buildPriceButton(
              amount: _voicePrice,
              onPressed: () => _showEditPriceDialog(
                title: '语音价格设置',
                initial: _voicePrice,
                onSaved: (v) => setState(() => _voicePrice = v),
              ),
            ),
          ),
        ],
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

  /// 右側白底陰影按鈕（展示金幣＋價格文字）
  Widget _buildPriceButton({
    required int amount,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
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
            Image.asset('assets/icon_gold1.png', width: 18, height: 18),
            const SizedBox(width: 6),
            Text(
              '$amount币 / 分钟',
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ),
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
          title: Text(title, textAlign: TextAlign.center,style: const TextStyle(fontSize: 16)),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
          content: SizedBox(
            width: 300,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                      hintText: '請輸入價格',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
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
                if (v < 1 || v > 1000000) {
                  Fluttertoast.showToast(msg: '金額必須在 1 到 1,000,000 之間');
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

    if (result != null) {
      onSaved(result);
    }
  }
}