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

    // 註冊攔截器
    _dio.interceptors.addAll([
      AuthInterceptor(ref), // 負責處理 token 攔截
      if (kDebugMode) LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  Future<Response> get(
      String path, {
        Map<String, dynamic>? queryParameters,
      }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
      String path, {
        dynamic data,
      }) async {
    return _dio.post(path, data: data);
  }

  Future<Response> put(
      String path, {
        dynamic data,
      }) async {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(
      String path,
      ) async {
    return _dio.delete(path);
  }
}
