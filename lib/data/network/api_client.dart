import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import 'auth_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient(AppConfig config, Ref ref) {
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
}
