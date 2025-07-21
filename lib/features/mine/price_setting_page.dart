import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:flutter/cupertino.dart';

class PriceSettingPage extends StatefulWidget {
  const PriceSettingPage({super.key});

  @override
  State<PriceSettingPage> createState() => _PriceSettingPageState();
}

class _PriceSettingPageState extends State<PriceSettingPage> {
  bool videoEnabled = false;
  bool voiceEnabled = false;

  @override
  Widget build(BuildContext context) {
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
          _buildItem(
            iconPath: 'assets/icon_set_price_1.svg',
            label: '视频接听',
            trailing: CupertinoSwitch(
              value: videoEnabled,
              onChanged: (value) {
                setState(() => videoEnabled = value);
              },
              activeColor: Colors.pinkAccent,
              trackColor: const Color(0xFFEDEDED),
            ),
          ),
          _buildItem(
            iconPath: 'assets/icon_set_price_2.svg',
            label: '视频价格设置',
            trailing: _buildPriceText('100'),
          ),
          _buildItem(
            iconPath: 'assets/icon_set_price_3.svg',
            label: '语音接听',
            trailing: CupertinoSwitch(
              value: voiceEnabled,
              onChanged: (value) {
                setState(() => voiceEnabled = value);
              },
              activeColor: Colors.pinkAccent,
              trackColor: const Color(0xFFEDEDED),
            ),
          ),
          _buildItem(
            iconPath: 'assets/icon_set_price_4.svg',
            label: '语音价格设置',
            trailing: _buildPriceText('80'),
          ),
        ],
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
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildPriceText(String amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/icon_gold1.png', width: 18, height: 18),
        const SizedBox(width: 4),
        Text('$amount币 / 分钟',
            style: const TextStyle(fontSize: 14, color: Colors.black)),
      ],
    );
  }
}
