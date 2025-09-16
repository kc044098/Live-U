import 'dart:convert';

import 'package:riverpod/riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_client_provider.dart';
import '../../data/network/api_endpoints.dart';
import '../home/live_list_page.dart';
import '../profile/profile_controller.dart';
import 'model/coin_packet.dart';
import 'model/finance_record.dart';
import 'model/recharge_detail.dart';
import 'model/recharge_record.dart';

class WalletRepository {
  WalletRepository(this._api);
  final ApiClient _api;

  Future<(int gold, int? vipExpire)> fetchMoneyCash() async {
    final response = await _api.post(ApiEndpoints.moneyCash);
    final raw = response.data is String ? jsonDecode(response.data) : response.data;
    final data = (raw['data'] ?? {}) as Map<String, dynamic>;
    final gold = (data['gold'] ?? 0) is num ? (data['gold'] as num).toInt() : 0;
    final vipExpire = (data['vip_expire'] == null)
        ? null
        : ((data['vip_expire'] as num).toInt());
    return (gold, vipExpire);
  }

  /// 測試充值 API：POST ApiEndpoints.recharge，body: {"gold": <int>}
  /// 充值：
  /// - 自訂金額：傳 gold
  /// - 禮包：傳 id
  Future<void> rechargeGold({int? gold, int? id}) async {
    // 兩者必擇其一
    if ((gold == null && id == null) || (gold != null && id != null)) {
      throw ArgumentError('rechargeGold: provide exactly one of gold or id');
    }

    final Map<String, dynamic> data = (id != null) ? {'id': id} : {'gold': gold};

    final resp = await _api.post(
      ApiEndpoints.recharge,
      data: data,
    );

    // 預期：{"code":200,"message":"success","data":null}
    final ok = (resp.data is Map) && (resp.data['code'] == 200);
    if (!ok) {
      final msg = (resp.data is Map)
          ? (resp.data['message']?.toString() ?? '充值失敗')
          : '充值失敗';
      throw Exception(msg);
    }
  }

  Future<List<FinanceRecord>> fetchFinanceList({required int page}) async {
    final res = await _api.post(
      ApiEndpoints.financeList,
      data: {'page': page},
    );

    final raw = res.data is String ? jsonDecode(res.data as String) : res.data;

    if (raw is! Map) {
      throw Exception('帳變紀錄回傳格式錯誤');
    }

    final code = raw['code'];
    final message = raw['message']?.toString();

    // ✅ 後端說 Not Found → 視為沒有更多資料
    if (code == 100 && (message?.toLowerCase() == 'not found')) {
      return <FinanceRecord>[];
    }

    // 其它非 200 視為錯誤
    if (code != 200) {
      throw Exception(message ?? '取得帳變紀錄失敗');
    }

    // 200：正常解析
    final data = raw['data'];
    final listRaw = (data is Map ? (data['list'] ?? []) : []) as List;

    return listRaw
        .whereType<Map>() // 保險：只處理 Map
        .map((e) => FinanceRecord.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  // 充值明細
  Future<RechargeDetail> fetchRechargeDetail({required int id}) async {
    final res = await _api.post(ApiEndpoints.rechargeDetail, data: {'id': id});
    final raw = res.data is String ? jsonDecode(res.data) : res.data;

    if (raw is! Map) throw Exception('充值詳情回傳格式錯誤');
    final code = raw['code'];
    final msg = raw['message']?.toString();

    if (code != 200) {
      // 後端偶會回 Not Found
      if (code == 100 && (msg?.toLowerCase() == 'not found')) {
        throw Exception('找不到該充值單');
      }
      throw Exception(msg ?? '取得充值詳情失敗');
    }

    final data = raw['data'];
    if (data is! Map) throw Exception('充值詳情資料缺失');
    return RechargeDetail.fromJson(Map<String, dynamic>.from(data));
  }


  /// 充值明細列表
  /// 參數：page 起始 1
  /// 回傳：單頁紀錄（後端回空陣列表示到底）
  Future<List<RechargeRecord>> fetchRechargeList({required int page}) async {
    final resp = await _api.post(
      ApiEndpoints.rechargeList,
      data: {"page": page},
    );

    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;
    if (raw is! Map || raw['code'] != 200) {
      final msg = raw is Map ? (raw['message']?.toString() ?? '取得充值明細失敗') : '取得充值明細失敗';
      throw Exception(msg);
    }

    final data = (raw['data'] ?? {}) as Map<String, dynamic>;
    final listRaw = (data['list'] ?? []) as List;
    return listRaw
        .whereType<Map>()
        .map((e) => RechargeRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<CoinPacket>> fetchCoinPackets({int page = 1}) async {
    final res = await _api.post(ApiEndpoints.coinPacketList, data: {'page': page});
    final data = (res.data['data'] as Map<String, dynamic>?) ?? const {};
    final list = (data['list'] as List?) ?? const [];
    return list
        .map((e) => CoinPacket.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

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
    orElse: () => user,
  );
});

final coinPacketsProvider = FutureProvider<List<CoinPacket>>((ref) async {
  final repo = ref.read(walletRepositoryProvider);
  return repo.fetchCoinPackets(page: 1);
});
