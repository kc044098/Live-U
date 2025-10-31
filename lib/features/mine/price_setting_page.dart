import 'package:djs_live_stream/features/mine/user_repository_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../l10n/l10n.dart';

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
  bool _loadingInit = true;

  @override
  void initState() {
    super.initState();
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    setState(() => _loadingInit = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      final map  = await repo.fetchCallPrices();

      int _clamp(int v) => v.clamp(kMinPrice, kMaxPrice);

      setState(() {
        _videoPrice = _clamp(map['video_price'] ?? _videoPrice);
        _voicePrice = _clamp(map['voice_price'] ?? _voicePrice);
        _loadingInit = false;
      });
    } catch (e) {
      debugPrint('[Price] load error: $e');
      setState(() => _loadingInit = false);
      // i18n
      Fluttertoast.showToast(msg: S.of(context).loadPriceFailedUsingDefaults);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.priceSetting, style: const TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadingInit ? null : _loadPrices,
            tooltip: s.refresh, // 使用既有的「重新整理 / Refresh」
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: _loadingInit
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 視頻價格
          _buildItem(
            iconPath: 'assets/icon_set_price_2.svg',
            label: s.videoPriceSettings,
            trailing: _buildPriceButton(
              context: context,
              amount: _videoPrice,
              loading: _savingVideo,
              onPressed: _savingVideo
                  ? null
                  : () => _showEditPriceDialog(
                title: s.videoPriceSettings,
                initial: _videoPrice,
                onSaved: (v) => _applyPrice(isVideo: true, value: v),
              ),
            ),
          ),

          // 語音價格
          _buildItem(
            iconPath: 'assets/icon_set_price_4.svg',
            label: s.voicePriceSettings,
            trailing: _buildPriceButton(
              context: context,
              amount: _voicePrice,
              loading: _savingVoice,
              onPressed: _savingVoice
                  ? null
                  : () => _showEditPriceDialog(
                title: s.voicePriceSettings,
                initial: _voicePrice,
                onSaved: (v) => _applyPrice(isVideo: false, value: v),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // + 加上 context 以便取多語系
  Widget _buildPriceButton({
    required BuildContext context,
    required int amount,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    final s = S.of(context);
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
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
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
            ] else ...[
              Image.asset('assets/icon_gold1.png', width: 18, height: 18),
              const SizedBox(width: 6),
            ],
            Text(
              // 例：100 金幣 / 分鐘 ； English：100 coins / min
              '$amount${s.coinsUnit} / ${s.minuteUnit}',
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ],
        ),
      ),
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
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          trailing,
        ],
      ),
    );
  }

  Future<void> _showEditPriceDialog({
    required String title,
    required int initial,
    required ValueChanged<int> onSaved,
  }) async {
    final controller = TextEditingController(text: initial.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final s = S.of(ctx);
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
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      hintText: s.enterPriceRangeHint(kMinPrice, kMaxPrice),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.commonCancel)),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                final v = int.tryParse(text);
                if (v == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(s.pleaseEnterValidNumber)),
                  );
                  return;
                }
                if (v < kMinPrice || v > kMaxPrice) {
                  Fluttertoast.showToast(msg: s.priceMustBeBetween(kMinPrice, kMaxPrice));
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: Text(s.commonSave),
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
    final s = S.of(context);
    if (value < kMinPrice || value > kMaxPrice) {
      Fluttertoast.showToast(msg: s.priceMustBeBetween(kMinPrice, kMaxPrice));
      return;
    }
    if (_silentBusy) return;
    _silentBusy = true;

    final prev = isVideo ? _videoPrice : _voicePrice;

    setState(() {
      if (isVideo) {
        _videoPrice = value;
        _savingVideo = true;
      } else {
        _voicePrice = value;
        _savingVoice = true;
      }
    });

    try {
      await ref.read(userRepositoryProvider).setPrice(isVideo: isVideo, price: value);
      Fluttertoast.showToast(msg: s.saveSuccess);
    } catch (_) {
      setState(() {
        if (isVideo) {
          _videoPrice = prev;
        } else {
          _voicePrice = prev;
        }
      });
      Fluttertoast.showToast(msg: s.saveFailedTryLater);
    } finally {
      setState(() {
        _savingVideo = false;
        _savingVoice = false;
      });
      _silentBusy = false;
    }
  }
}

