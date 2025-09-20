
import 'package:flutter/material.dart';

class IosPurchasePage extends StatelessWidget {
  final int? packetId;
  final double displayAmount;
  const IosPurchasePage({super.key, required this.packetId, required this.displayAmount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apple 內購')),
      body: Center(
        child: Text('待串接 Apple 內購（packetId=$packetId, \$${displayAmount.toStringAsFixed(2)}）'),
      ),
    );
  }
}