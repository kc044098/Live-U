import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class EmojiPack {
  final Map<String, String> codeToAsset; // '1f600' -> 'assets/emojis/basic/1f600.png'
  EmojiPack(this.codeToAsset);

  static const tokenPrefix = '[/';
  static const tokenSuffix = ']';
  static final tokenReg = RegExp(r'\[\/([0-9a-fA-F_]+)\]'); // [/1f600]

  String tokenFor(String code) => '$tokenPrefix$code$tokenSuffix';
  String? assetOf(String code) => codeToAsset[code.toLowerCase()];
  Iterable<String> get codes => codeToAsset.keys;

  /// 從 AssetManifest 自動掃描某資料夾（例：assets/emojis/basic/）
  static Future<EmojiPack> loadFromFolder(String folder) async {
    final manifestJson = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest = jsonDecode(manifestJson);

    final Map<String, String> map = {};
    manifest.keys
        .where((k) => k.startsWith(folder) && k.toLowerCase().endsWith('.png'))
        .forEach((path) {
      final file = path.split('/').last; // 1f600.png
      final code = file.split('.').first.toLowerCase(); // 1f600
      map[code] = path;
    });

    return EmojiPack(map);
  }
}