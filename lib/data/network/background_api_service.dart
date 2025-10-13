// background_api_service.dart
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:djs_live_stream/features/widgets/tools/image_resolver.dart';
import 'package:flutter/cupertino.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

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
            if (_ref.exists(otherUserProvider(uidInt))) {
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

  /// 多張頭像上傳後更新會員資訊
  Future<void> uploadAvatarsAndUpdate({
    required List<String> paths,
    void Function(double progress)? onProgress,
  }) {
    return _enqueue(() async {
      // 1) log + 正規化成 3 格
      final slots = List<String>.from(paths)..length = 3;
      for (var i = 0; i < 3; i++) { slots[i] = (i < paths.length) ? (paths[i] ?? '') : ''; }
      debugPrint('[AvatarSvc] INPUT slots=$slots');

      String _pathOnly(String u) {
        if (!u.isHttp) return u;
        try {
          final uri = Uri.parse(u);
          final p = uri.path.isEmpty ? u : uri.path;
          return p.startsWith('/') ? p : '/$p';
        } catch (_) {
          return u;
        }
      }

      // 2) 逐格處理，保留位置
      final result = List<String>.from(slots);
      final totalToUpload = <int>[];

      for (int i = 0; i < 3; i++) {
        final p = slots[i];
        if (p.isEmpty) {
          result[i] = '';
          continue;
        }
        if (p.isServerRelative) {
          // 已是 /image/... 之類
          result[i] = p;
          continue;
        }
        if (p.isHttp) {
          // http 全路徑 → 僅取 path
          result[i] = _pathOnly(p);
          continue;
        }
        // 其它一律視為本地檔（file:// / storage / content://）
        totalToUpload.add(i);
      }

      debugPrint('[AvatarSvc] toUploadIndices=$totalToUpload');

      // 3) 上傳本地檔，填回原位置
      for (final idx in totalToUpload) {
        final f = await _toReadableFile(slots[idx]);
        if (f != null) {
          final url = await _withRetry(() => _repo.uploadToS3Avatar(f));
          result[idx] = _pathOnly(url); // 只存 S3 相對路徑
        } else {
          // 讀不到檔 → 清空該格，避免髒資料
          result[idx] = '';
        }
        onProgress?.call(
          (totalToUpload.indexOf(idx) + 1) / (totalToUpload.isEmpty ? 1 : totalToUpload.length),
        );
      }

      // 4) 送到後端（固定 3 格，允許空字串）
      debugPrint('[AvatarSvc] UPDATE avatar=$result');
      await _withRetry(() => _repo.updateMemberInfo({'avatar': result}));

      // 5) 更新 user（只會是相對路徑/空字串）
      final me = _ref.read(userProfileProvider);
      if (me != null) {
        final updated = me.copyWith(photoURL: result);
        _ref.read(userProfileProvider.notifier).setUser(updated);
        await UserLocalStorage.saveUser(updated);
      }

      debugPrint('[AvatarSvc] DONE avatar=${result}');
    });
  }


  Future<File?> _toReadableFile(String src) async {
    try {
      if (src.isContentUri) {
        final xf = XFile(src);
        final bytes = await xf.readAsBytes();
        final dir = await getTemporaryDirectory();
        final f = File('${dir.path}/pick_${DateTime.now().microsecondsSinceEpoch}.bin');
        await f.writeAsBytes(bytes);
        return f;
      }
      final f = File(src);
      if (await f.exists()) return f;
    } catch (_) {}
    return null;
  }

  Future<UserModel> refreshMe(UserModel me) {
  return _enqueue(() => _withRetry(() => _repo.getMemberInfo(me)));
  }
}


