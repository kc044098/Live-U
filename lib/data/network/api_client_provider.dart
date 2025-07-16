import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/providers/app_config_provider.dart';
import '../../data/network/api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  return ApiClient(config, ref); // ✅ 傳入 ref
});

