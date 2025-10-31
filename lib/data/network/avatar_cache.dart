import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:djs_live_stream/features/widgets/tools/image_resolver.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

/// 全域 Avatar 專用快取（可調整容量與有效期）
class AvatarCache {
  static final CacheManager manager = CacheManager(
    Config(
      'avatarCache',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
    ),
  );

  // 簡單 base64 轉 bytes 的快取，避免重複 decode
  static final Map<String, List<int>> base64Bytes = {};
}

/// 建議做成方法（可帶 context 計算 DPR 對應的像素尺寸）
/// 建議做成方法（可帶 context 計算 DPR 對應的像素尺寸）
ImageProvider<Object> buildAvatarProvider({
  required String avatarUrl,
  required BuildContext context,
  double logicalSize = 48, // CircleAvatar 半徑 24 -> 邏輯尺寸約 48
}) {
  final dpr = MediaQuery.of(context).devicePixelRatio;
  final targetPx = (logicalSize * dpr).round(); // 目標解碼大小（像素）

  if (avatarUrl.isEmpty || avatarUrl.isLocalAbs || avatarUrl.isDataUri) {
    return const AssetImage('assets/my_icon_defult.jpeg');
  }

  if (avatarUrl.startsWith('http')) {
    // ✅ 網路圖：快取 + 降解析度解碼
    return ResizeImage(
      CachedNetworkImageProvider(
        avatarUrl,
        cacheManager: AvatarCache.manager,
      ),
      width: targetPx,
      height: targetPx,
    );
  }

  if (avatarUrl.startsWith('data:image') || avatarUrl.length > 100) {
    // ✅ base64：先快取 bytes，再降解析度解碼
    final key = avatarUrl.length > 128 ? avatarUrl.substring(0, 128) : avatarUrl; // 簡化 key
    final bytes = AvatarCache.base64Bytes.putIfAbsent(
      key,
          () {
        final pure = avatarUrl.contains(',')
            ? avatarUrl.split(',').last
            : avatarUrl;
        return base64Decode(pure);
      },
    );
    return ResizeImage(
      MemoryImage(bytes is Uint8List ? bytes : Uint8List.fromList(bytes)),
      width: targetPx, height: targetPx,
    );
  }

  // 本地檔案
  final file = File(avatarUrl);
  if (file.existsSync()) {
    return ResizeImage(FileImage(file), width: targetPx, height: targetPx);
  }

  // 其他情況用預設圖
  return const AssetImage('assets/my_icon_defult.jpeg');
}