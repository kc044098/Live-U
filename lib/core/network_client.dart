import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../data/network/auth_interceptor.dart';

class NetworkClient {
  final Dio _dio;

  NetworkClient(AppConfig config)
      : _dio = Dio(BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )) {
    _dio.interceptors.addAll([
      AuthInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
}
