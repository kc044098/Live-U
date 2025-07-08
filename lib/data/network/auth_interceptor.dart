import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 模擬：從本地取得 token
    const token = "fake_token";
    options.headers['Authorization'] = 'Bearer $token';
    return super.onRequest(options, handler);
  }
}