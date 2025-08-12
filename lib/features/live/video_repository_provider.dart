import '../../config/providers/app_config_provider.dart';
import '../profile/profile_controller.dart';
import 'video_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/network/api_client_provider.dart';

final videoRepositoryProvider = Provider<VideoRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  final config = ref.watch(appConfigProvider);
  return VideoRepository(api, config, ref);
});