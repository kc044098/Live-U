// background_api_service.dart
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/user_local_storage.dart';
import '../../features/mine/user_repository.dart';
import '../../features/mine/user_repository_provider.dart';
import '../../features/profile/profile_controller.dart';
import '../models/user_model.dart';

class BackgroundApiService {
  final UserRepository _repo;
  final Ref _ref;

  BackgroundApiService(this._repo, this._ref);

  Future<void> _last = Future.value();

  Future<T> _enqueue<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _last = _last.then((_) async {
      try {
        final res = await task();
        if (!completer.isCompleted) completer.complete(res);
      } catch (e, st) {
        if (!completer.isCompleted) completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<T> _withRetry<T>(
      Future<T> Function() run, {
        int maxAttempts = 3,
        Duration initialDelay = const Duration(milliseconds: 400),
      }) async {
    var attempt = 0;
    var delay = initialDelay;
    while (true) {
      attempt++;
      try {
        return await run();
      } catch (_) {
        if (attempt >= maxAttempts) rethrow;
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  Future<void> updateMemberInfoQueued(Map<String, dynamic> updateData) {
    return _enqueue(() => _withRetry(() async {
      await _repo.updateMemberInfo(updateData);
      Future.microtask(() {
        if (_ref.exists(userProfileProvider)) {
          final me = _ref.read(userProfileProvider);
          if (me != null) {
            _ref.invalidate(userProfileProvider);
          }
        }
      });
    }));
  }

  Future<String> uploadAvatarQueued(File file) {
    return _enqueue(() => _withRetry(() => _repo.uploadToS3Avatar(file)));
  }

  Future<void> likeUserAndRefresh({
    required String targetUid,
    void Function()? onSuccess,
    void Function(Object error, StackTrace st)? onError,
  }) async {
    return _enqueue(() async {
      try {
        await _withRetry(() => _repo.memberFocus(targetUid: targetUid));
        final uidInt = int.tryParse(targetUid);
        if (uidInt != null) {
          Future.microtask(() {
            if (_ref.exists(otherUserProvider(uidInt))) { // otherUserProvider 沒帶參數嗎？
              _ref.invalidate(otherUserProvider(uidInt));
            }
          });
        }
        onSuccess?.call();
      } catch (e, st) {
        onError?.call(e, st);
        rethrow;
      }
    });
  }

  // ✅ 新增：影片按讚 + （可選）刷新相關列表
  Future<void> likeVideoAndRefresh({
    required int videoId,
    int? ownerUid,                  // 該影片所屬用戶，用來 refresh 他的動態
    void Function()? onSuccess,
    void Function(Object error, StackTrace st)? onError,
  }) async {
    return _enqueue(() async {
      try {
        await _withRetry(() => _repo.likeVideo(id: videoId));

        // （可選）刷新：如果你有單支影片的 provider，在這裡 invalidate
        // if (_ref.exists(videoDetailProvider(videoId))) {
        //   _ref.invalidate(videoDetailProvider(videoId));
        // }

        onSuccess?.call();
      } catch (e, st) {
        onError?.call(e, st);
        rethrow;
      }
    });
  }

  Future<String> uploadFileQueued({
    required File file,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onProgress,
  }) {
    return _enqueue(() async {
      return _withRetry(() => _repo.uploadToS3(
        file: file,
        cancelToken: cancelToken,
        onProgress: onProgress,
      ));
    });
  }

  /// 多張頭像上傳後更新會員資訊（cdnBase 可選）
  Future<void> uploadAvatarsAndUpdate({
    required List<String> paths,  // 可能混合 http 與本地路徑
    String? cdnBase,              // 有就拼上（只對「非 http」的上傳結果）
    void Function(double progress)? onProgress, // 可選：0~1 進度回呼（不畫 UI）
  }) {
    return _enqueue(() async {
      // 1) 將 http 的直接保留，非 http 的排進待上傳
      final retained = <String>[];
      final toUpload = <String>[];
      for (final p in paths) {
        if (p.isEmpty) continue;
        if (p.isHttp) {
          retained.add(p);
        } else {
          toUpload.add(p);
        }
      }

      // 2) 依序上傳本地檔（序列化避免併發）
      final uploaded = <String>[];
      for (var i = 0; i < toUpload.length; i++) {
        final localPath = toUpload[i];
        final file = File(localPath);
        if (await file.exists()) {
          String url = await _withRetry(() => _repo.uploadToS3Avatar(file));
          // 只對非 http 的「後端回傳相對路徑」加上 cdnBase（依你後端而定）
          if (!url.isHttp && cdnBase != null && cdnBase.isNotEmpty) {
            url = cdnBase.endsWith('/') ? '${cdnBase.substring(0, cdnBase.length - 1)}$url' : '$cdnBase$url';
          }
          uploaded.add(url);
        }
        // 粗略進度（非必要）
        if (onProgress != null) {
          final done = retained.length + uploaded.length;
          final total = retained.length + toUpload.length;
          onProgress(total == 0 ? 1.0 : done / total);
        }
      }

      final finalList = <String>[
        ...retained,
        ...uploaded,
      ];

      // 3) 更新後端
      await _withRetry(() => _repo.updateMemberInfo({'avatar': finalList}));

      // 4) 同步到本地（不需要 dialog）
      final me = _ref.read(userProfileProvider);
      if (me != null) {
        final updated = me.copyWith(photoURL: finalList);
        _ref.read(userProfileProvider.notifier).setUser(updated);
        await UserLocalStorage.saveUser(updated);
      }
    });
  }

  Future<UserModel> refreshMe(UserModel me) {
    return _enqueue(() => _withRetry(() => _repo.getMemberInfo(me)));
  }
}

extension _UrlHelpers on String {
  bool get isHttp => startsWith('http://') || startsWith('https://');
}