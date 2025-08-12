import 'package:dio/dio.dart';

import '../../core/user_local_storage.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../locale_provider.dart';

class AuthInterceptor extends Interceptor {
  final Ref ref;

  AuthInterceptor(this.ref);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final user = await UserLocalStorage.getUser();
    final token = user?.primaryLogin?.token;
    if (token != null && token.isNotEmpty) {
      options.headers['Token'] = token.trim();
    }

    // UID
    final uid = user?.uid;
    if (uid != null && uid.isNotEmpty) {
      options.headers['X-UID'] = uid;
    }

    final locale = ref.read(localeProvider); // ✅ 語系 provider
    options.headers['Accept-Language'] = locale.languageCode;

    return super.onRequest(options, handler);
  }
}
