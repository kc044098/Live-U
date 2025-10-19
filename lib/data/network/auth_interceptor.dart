import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/user_local_storage.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_controller.dart';
import '../locale_provider.dart';
class AuthInterceptor extends Interceptor {
  final Ref ref;
  AuthInterceptor(this.ref);

  static bool _loggingOut = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final user = await UserLocalStorage.getUser();
    final token = user?.primaryLogin?.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Token'] = token.trim();
    }
    final uid = user?.uid;
    if (uid != null && uid.isNotEmpty) {
      options.headers['X-UID'] = uid;
    }
    final locale = ref.read(localeProvider);
    options.headers['Accept-Language'] = locale.languageCode;
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    try {
      // 兼容你的 {code, message, data} 规范
      final body = response.data;
      if (body is Map) {
        final code = (body['code'] is num) ? (body['code'] as num).toInt() : null;
        if (code == 600) {
          // token 过期 → 统一登出
          await AuthService(ref.read).forceLogout(tip: 'Session expired, please sign in again');
          return; // 不再把响应交给后续
        }
      }
    } catch (_) {}
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final http = err.response?.statusCode ?? 0;
    final body = err.response?.data;
    int? code;
    if (body is Map && body['code'] is int) code = body['code'] as int;

    if (http == 401 || http == 403 ||code == 600) {
      if (!_loggingOut) {
        _loggingOut = true;
        unawaited(AuthService(ref.read).forceLogout(tip: '登录已过期，请重新登录'));
        Future.delayed(const Duration(milliseconds: 500), () => _loggingOut = false);
      }
    }
    return super.onError(err, handler);
  }
}
