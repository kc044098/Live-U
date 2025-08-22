import 'package:djs_live_stream/features/mine/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../data/network/api_client_provider.dart';
import '../../data/network/background_api_service.dart';
import 'model/vip_plan.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserRepository(apiClient);
});

final otherUserProvider = AutoDisposeFutureProvider.family<UserModel, int>((ref, id) async {
  final repo = ref.read(userRepositoryProvider);
  return repo.getMemberInfoById(id);
});

final backgroundApiServiceProvider = Provider<BackgroundApiService>((ref) {
  final repo = ref.read(userRepositoryProvider);
  return BackgroundApiService(repo, ref);
});

final vipPlansProvider = FutureProvider<List<VipPlan>>((ref) async {
  final repo = ref.read(userRepositoryProvider);
  return repo.fetchVipPlans();
});

