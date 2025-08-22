// background_api_service.dart
import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';

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

  /// 只保留 path（/ 開頭），把 http(s) 與查詢參數等都去掉
  String _pathOnly(String u) {
    if (!u.isHttp) return u; // 本地檔或已是相對路徑
    try {
      final uri = Uri.parse(u);
      final p = uri.path.isEmpty ? u : uri.path;
      return p.startsWith('/') ? p : '/$p';
    } catch (_) {
      return u;
    }
  }

  /// 多張頭像上傳後更新會員資訊
  Future<void> uploadAvatarsAndUpdate({
    required List<String> paths,
    void Function(double progress)? onProgress,
  }) {
    return _enqueue(() async {
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

      final retained = <String>[]; // 伺服器相對路徑（或已經是 /avatar/.. 等）
      final toUpload = <String>[]; // 本地檔（含 /storage… /data…、content://、file://、相對檔名）

      for (final p in paths) {
        if (p.isEmpty) continue;
        if (p.isHttp) {
          retained.add(_pathOnly(p));
        } else if (p.isServerRelative) {
          retained.add(p); // 僅 /avatar/... 這類
        } else {
          toUpload.add(p); // 本地絕對/相對/URI 皆列入上傳
        }
      }

      final uploaded = <String>[];
      for (var i = 0; i < toUpload.length; i++) {
        final f = await _toReadableFile(toUpload[i]);
        if (f != null) {
          final url = await _withRetry(() => _repo.uploadToS3Avatar(f));
          uploaded.add(_pathOnly(url)); // 只存相對路徑
        }
        onProgress?.call(
            (retained.length + uploaded.length) /
                ((retained.length + toUpload.length) == 0 ? 1 : (retained.length + toUpload.length))
        );
      }

      final finalList = <String>[...retained, ...uploaded];

      await _withRetry(() => _repo.updateMemberInfo({'avatar': finalList}));

      final me = _ref.read(userProfileProvider);
      if (me != null) {
        final updated = me.copyWith(photoURL: finalList); // 仍只存相對路徑
        _ref.read(userProfileProvider.notifier).setUser(updated);
        await UserLocalStorage.saveUser(updated);
      }
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

extension PathX on String {
  bool get isHttp => startsWith('http://') || startsWith('https://');
  bool get isDataUri => startsWith('data:image');
  bool get isContentUri => startsWith('content://') || startsWith('file://');

  // 常見本地絕對路徑（Android/iOS）
  bool get isLocalAbs =>
      startsWith('/storage/') || // Android
          startsWith('/mnt/')     || // Android
          startsWith('/data/')    || // Android app data
          startsWith('/var/');       // iOS

  /// 只有像 /avatar/xxx.jpg 這種「伺服器相對路徑」才回 true
  bool get isServerRelative => startsWith('/') && !isLocalAbs;
}

/// 只在「伺服器相對路徑」時拼 CDN，其餘直接回傳原字串
String joinCdnIfNeeded(String raw, String? cdnBase) {
  if (raw.isEmpty || raw.isHttp || raw.isDataUri || raw.isContentUri || raw.isLocalAbs) {
    return raw; // 不拼
  }
  if (!raw.isServerRelative) return raw; // 例如本地相對檔案名，也不拼
  if (cdnBase == null || cdnBase.isEmpty) return raw;

  final b = cdnBase.endsWith('/') ? cdnBase.substring(0, cdnBase.length - 1) : cdnBase;
  final p = raw.startsWith('/') ? raw : '/$raw';
  return '$b$p';
}

