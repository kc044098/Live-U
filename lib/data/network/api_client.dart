import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/providers/app_config_provider.dart';
import '../../core/error_handler.dart';
import '../../features/auth/providers/auth_controller.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio _dio;
  final Ref ref;

  ApiClient(AppConfig config, Ref ref)
      : ref = ref {
    _dio = Dio(BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(ref),
      if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  // 有時 service 需要更底層能力，提供唯讀 getter（可選）
  Dio get dio => _dio;

  Future<Response> get(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
      }) async {
    final response = await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
    return _normalizeResponse(response);
  }

  Future<Response> post(
      String path, {
        dynamic data,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) async {
    final response = await _dio.post(
      path,
      data: data ?? {},
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return _normalizeResponse(response);
  }

  Future<Response> put(
      String path, {
        dynamic data,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) async {
    final response = await _dio.put(
      path,
      data: data ?? {},
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return _normalizeResponse(response);
  }

  Future<Response> delete(
      String path, {
        dynamic data,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    final response = await _dio.delete(
      path,
      data: data,
      options: options,
      cancelToken: cancelToken,
    );
    return _normalizeResponse(response);
  }

  Response _normalizeResponse(Response response) {
    if (response.data is String) {
      try {
        response.data = jsonDecode(response.data as String);
      } catch (_) {
        // 不是 JSON，保持原樣
      }
    }
    return response;
  }

  Future<Map<String, dynamic>> getOk(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
        Set<int> alsoOkCodes = const {}, // e.g. {100} 有些 API 把 100 當「沒有更多資料」
      }) async {
    final res = await get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
    return _unwrapOrThrow(res, alsoOkCodes: alsoOkCodes);
  }

  Future<Map<String, dynamic>> postOk(
      String path, {
        dynamic data,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        Set<int> alsoOkCodes = const {},
      }) async {
    final res = await post(
      path,
      data: data,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return _unwrapOrThrow(res, alsoOkCodes: alsoOkCodes);
  }

  Future<Map<String, dynamic>> putOk(
      String path, {
        dynamic data,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        Set<int> alsoOkCodes = const {},
      }) async {
    final res = await put(
      path,
      data: data,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return _unwrapOrThrow(res, alsoOkCodes: alsoOkCodes);
  }

  Future<Map<String, dynamic>> deleteOk(
      String path, {
        dynamic data,
        Options? options,
        CancelToken? cancelToken,
        Set<int> alsoOkCodes = const {},
      }) async {
    final res = await delete(
      path,
      data: data,
      options: options,
      cancelToken: cancelToken,
    );
    return _unwrapOrThrow(res, alsoOkCodes: alsoOkCodes);
  }

  /// 私有：檢查 {code, message, data} 慣例，非 200 → 丟 ApiException
  Map<String, dynamic> _unwrapOrThrow(Response res, {Set<int> alsoOkCodes = const {}}) {
    final raw = res.data;
    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      final code = map['code'];

      if (code is int) {
        // ✅ 把 0 也當作成功
        if (code == 200 || code == 0 || alsoOkCodes.contains(code)) {
          return map;
        }
        if (code == 600 || code == 401) {
          // 不阻塞目前流程，讓導頁與錯誤顯示各自進行
          unawaited(AuthService(ref.read).forceLogout(tip: 'Login expired, please sign in again.'));
        }

        final serverMsg = map['message']?.toString();
        final msg = AppErrorCatalog.messageFor(code, serverMessage: serverMsg);
        throw ApiException(code, msg);
      }
    }
    throw ApiException(-1, '資料格式錯誤');
  }
}
