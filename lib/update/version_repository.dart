// repositories/version_repository.dart
import 'package:djs_live_stream/update/update_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/network/api_client.dart';
import '../data/network/api_client_provider.dart';
import '../data/network/api_endpoints.dart';
import 'app_update.dart';

class VersionRepository {
  final ApiClient api; // 你項目裡已有的封裝

  VersionRepository(this.api);

  Future<AppUpdateInfo?> fetchLatestForIOS() async {
    final res = await api.postOk(ApiEndpoints.appLastestVersion, data: {'values': 'ios'});
    if (res['code'] == 0 && res['data'] != null) {
      return AppUpdateInfo.fromJson(res);
    }
    return null;
  }
}

final versionRepositoryProvider = Provider<VersionRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return VersionRepository(api);
});
final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService(ref));

