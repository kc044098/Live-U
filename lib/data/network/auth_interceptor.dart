import 'package:dio/dio.dart';

import '../../core/user_local_storage.dart';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../locale_provider.dart';

class AuthInterceptor extends Interceptor {
  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final user = await UserLocalStorage.getUser();
    final token = user?.idToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    final locale = ref.read(localeProvider); // ✅ 語系 provider
    options.headers['Accept-Language'] = locale.languageCode;

    return super.onRequest(options, handler);
  }
}
