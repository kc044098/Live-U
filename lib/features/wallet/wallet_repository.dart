import 'package:dio/dio.dart';
import 'package:riverpod/riverpod.dart';
import '../../core/error_handler.dart';
import '../../data/models/user_model.dart';
import '../../data/network/api_client.dart';
import '../../data/network/api_client_provider.dart';
import '../../data/network/api_endpoints.dart';
import '../profile/profile_controller.dart';
import 'model/coin_packet.dart';
import 'model/finance_record.dart';
import 'model/recharge_detail.dart';
import 'model/recharge_record.dart';
import 'model/withdraw_record.dart';

class WalletRepository {
  WalletRepository(this._api);

  final ApiClient _api;

  /// 取金幣/VIP 以及推廣相關數據
  /// 回傳：gold, vipExpire, inviteNum, totalIncome, cashAmount
  Future<
      ({
        int gold,
        int? vipExpire,
        int inviteNum,
        int totalIncome,
        int cashAmount,
      })> fetchMoneyCash() async {
    try {
      // 有些後端會用 100/404 表示「沒有資料」
      final map =
          await _api.postOk(ApiEndpoints.moneyCash, alsoOkCodes: {100, 404});
      final data = (map['data'] as Map?)?.cast<String, dynamic>() ?? const {};

      int _intOf(dynamic v) =>
          (v is num) ? v.toInt() : (int.tryParse(v?.toString() ?? '') ?? 0);

      final gold = _intOf(data['gold'] ?? 0);
      final vipExpireN = data['vip_expire'];
      final int? vipExpire = (vipExpireN == null)
          ? null
          : ((vipExpireN is num)
              ? vipExpireN.toInt()
              : int.tryParse('$vipExpireN'));

      final inviteNum = _intOf(data['invite_num'] ?? 0);
      final totalIncome = _intOf(data['total_income'] ?? 0);
      final cashAmount = _intOf(data['amount'] ?? 0);

      return (
        gold: gold,
        vipExpire: vipExpire,
        inviteNum: inviteNum,
        totalIncome: totalIncome,
        cashAmount: cashAmount,
      );
    } on DioException catch (e) {
      // 真正的 HTTP 404：視為沒有資料
      if (e.response?.statusCode == 404) {
        return (
          gold: 0,
          vipExpire: null,
          inviteNum: 0,
          totalIncome: 0,
          cashAmount: 0
        );
      }
      rethrow;
    }
  }

  /// 測試充值 API
  Future<void> rechargeGold({int? gold, int? id}) async {
    if ((gold == null && id == null) || (gold != null && id != null)) {
      throw ArgumentError('rechargeGold: provide exactly one of gold or id');
    }
    final data = (id != null) ? {'id': id} : {'gold': gold};

    // 非 200 的業務碼會自動丟 ApiException（統一由 AppErrorCatalog 映射訊息）
    await _api.postOk(ApiEndpoints.recharge, data: data);
  }

  Future<List<FinanceRecord>> fetchFinanceList({required int page}) async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.financeList,
        data: {'page': page},
        alsoOkCodes: {100, 404}, // 100/404 → 視為空清單
      );
      final data = map['data'] as Map?;
      final listRaw = (data?['list'] as List?) ?? const [];

      return listRaw
          .whereType<Map>()
          .map((e) => FinanceRecord.fromJson(e.cast<String, dynamic>()))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return <FinanceRecord>[];
      rethrow;
    }
  }

  /// 充值明細（單筆）
  Future<RechargeDetail> fetchRechargeDetail({required int id}) async {
    try {
      final map =
          await _api.postOk(ApiEndpoints.rechargeDetail, data: {'id': id});
      final data = map['data'];
      if (data is! Map) {
        throw ApiException(-1, 'No data');
      }
      return RechargeDetail.fromJson(Map<String, dynamic>.from(data));
    } on ApiException catch (e) {
      // 後端業務碼 100/404 → 視為找不到這筆（單筆詳情屬於「錯誤」）
      if (e.code == 100 || e.code == 404) {
        throw ApiException(404, 'No data');
      }
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ApiException(404, 'No data');
      }
      rethrow;
    }
  }

  /// 充值明細列表（分頁）
  Future<List<RechargeRecord>> fetchRechargeList({required int page}) async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.rechargeList,
        data: {"page": page},
        alsoOkCodes: {100, 404}, // 空資料
      );
      final data = (map['data'] as Map?) ?? const {};
      final list = (data['list'] as List?) ?? const [];

      return list
          .whereType<Map>()
          .map((e) => RechargeRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return <RechargeRecord>[];
      rethrow;
    }
  }

  /// 提現（動作型：任何非 200 都當錯）
  Future<void> withdraw({
    required String account,
    required int amount,
    required String bankCode,
    required String cardName,
  }) async {
    final payload = {
      "account": account,
      "amount": amount,
      "bank_code": bankCode,
      "card_name": cardName,
    };
    await _api.postOk(ApiEndpoints.withdraw, data: payload);
  }

  /// 取得提現列表（分頁）
  Future<List<WithdrawRecord>> fetchWithdrawList({required int page}) async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.withdrawList,
        data: {'page': page},
        alsoOkCodes: {100, 404}, // 空資料
      );
      final data = map['data'];
      if (data == null) return <WithdrawRecord>[];

      final listAny = (data is Map) ? data['list'] : null;
      if (listAny is! List) return <WithdrawRecord>[];

      return listAny.map<WithdrawRecord>((e) {
        return WithdrawRecord.fromJson(Map<String, dynamic>.from(e as Map));
      }).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return <WithdrawRecord>[];
      rethrow;
    }
  }

  Future<List<CoinPacket>> fetchCoinPackets({int page = 1}) async {
    try {
      final map = await _api.postOk(
        ApiEndpoints.coinPacketList,
        data: {'page': page},
        alsoOkCodes: {100, 404}, // 空資料
      );
      final data = (map['data'] as Map?) ?? const {};
      final list = (data['list'] as List?) ?? const [];
      return list
          .whereType<Map>()
          .map((e) => CoinPacket.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return <CoinPacket>[];
      rethrow;
    }
  }

  /// 驗證商店內購並發幣（動作型）
  /// - platform: 'android' / 'ios'
  /// - productId: 商店 product id
  /// - packetId: 後台禮包 id（可選）
  /// - purchaseTokenOrReceipt: Android=購買 token；iOS=base64 receipt
  Future<void> verifyIapAndCredit({
    required String platform,
    required String productId,
    int? packetId,
    required String purchaseTokenOrReceipt,
  }) async {
    final pf = platform.toLowerCase();
    final isAndroid = pf == 'android';
    final isIos = pf == 'ios';
    if (!isAndroid && !isIos) {
      throw ArgumentError('verifyIapAndCredit: platform must be "android" or "ios"');
    }

    final payload = <String, dynamic>{
      'product_id': productId,      // 商店商品 id
      if (isAndroid) 'transaction_id': purchaseTokenOrReceipt,
      if (isIos) 'transaction_id': purchaseTokenOrReceipt,
    };

    // 這是動作型 API：成功回 200 即可，不取回傳資料
    await _api.postOk(ApiEndpoints.iapVerify, data: payload);
  }

}

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return WalletRepository(api);
});

final walletBalanceProvider = FutureProvider<
    ({
      int gold,
      int? vipExpire,
      int inviteNum,
      int totalIncome,
      int cashAmount,
    })>((ref) async {
  final repo = ref.read(walletRepositoryProvider); // ← 用到 UserRepository
  return repo.fetchMoneyCash();
});

// 會把錢包資料（gold / vipExpire / inviteNum / totalIncome / cashAmount）合併到目前使用者
final currentUserWithWalletProvider = Provider<UserModel?>((ref) {
  final user = ref.watch(userProfileProvider);
  final walletAsync = ref.watch(walletBalanceProvider); // 已改成具名 record 的那個

  if (user == null) return null;

  return walletAsync.maybeWhen(
    data: (w) => user.copyWith(
      gold: w.gold,
      vipExpire: w.vipExpire,
      inviteNum: w.inviteNum,
      totalIncome: w.totalIncome,
      cashAmount: w.cashAmount,
    ),
    orElse: () => user,
  );
});

final coinPacketsProvider = FutureProvider<List<CoinPacket>>((ref) async {
  final repo = ref.read(walletRepositoryProvider);
  return repo.fetchCoinPackets(page: 1);
});
