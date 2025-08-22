import 'package:dio/dio.dart';

import '../../config/providers/app_config_provider.dart';
import '../../data/network/Api_client_interface.dart';
import '../../data/network/api_client.dart';
import '../profile/profile_controller.dart';
import 'video_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/network/api_client_provider.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final config = ref.watch(appConfigProvider);
  return VideoRepository(api, config, ref);
});


class _ApiClientAdapter implements IApiClient {
  final ApiClient _inner;
  _ApiClientAdapter(this._inner);
  @override
  Future<Response> post(String path, {data}) => _inner.post(path, data: data);
  @override
  String get baseUrl => _inner.dio.options.baseUrl;
}