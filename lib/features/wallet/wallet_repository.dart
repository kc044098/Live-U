import 'dart:convert';

import 'package:riverpod/riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_client_provider.dart';
import '../../data/network/api_endpoints.dart';
import '../profile/profile_controller.dart';

class WalletRepository {
  WalletRepository(this._api);
  final ApiClient _api;

  Future<(int gold, int? vipExpire)> fetchMoneyCash() async {
    final response = await _api.post(ApiEndpoints.moneyCash);
    final raw = response.data is String ? jsonDecode(response.data) : response.data;
    // 伺服器回傳格式:
    // {"code":200,"message":"success","data":{"gold":10000000,"amount":0,...,"vip_expire":1759981616}}
    final data = (raw['data'] ?? {}) as Map<String, dynamic>;
    final gold = (data['gold'] ?? 0) is num ? (data['gold'] as num).toInt() : 0;
    final vipExpire = (data['vip_expire'] == null)
        ? null
        : ((data['vip_expire'] as num).toInt());
    return (gold, vipExpire);
  }
}

// Provider：如果你已有 apiClientProvider，沿用它
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return WalletRepository(api);
});

final walletBalanceProvider = FutureProvider<(int gold, int? vipExpire)>((ref) async {
  final repo = ref.read(walletRepositoryProvider);
  return repo.fetchMoneyCash();
});

final currentUserWithWalletProvider = Provider<UserModel?>((ref) {
  final user = ref.watch(userProfileProvider);
  final walletAsync = ref.watch(walletBalanceProvider);

  if (user == null) return null;

  return walletAsync.maybeWhen(
    data: (tuple) => user.copyWith(gold: tuple.$1, vipExpire: tuple.$2),
    orElse: () => user, // 還沒抓到錢包資料就先用原本 user
  );
});