import 'dart:convert';

import 'package:flutter/cupertino.dart';
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
import 'model/withdraw_record.dart';

class WalletRepository {
  WalletRepository(this._api);
  final ApiClient _api;

  /// 取金幣/VIP 以及推廣相關數據
  /// 回傳：gold, vipExpire, inviteNum, totalIncome, cashAmount
  Future<({
  int gold,
  int? vipExpire,
  int inviteNum,
  int totalIncome,
  int cashAmount,
  })> fetchMoneyCash() async {
    final response = await _api.post(ApiEndpoints.moneyCash);
    final raw = response.data is String ? jsonDecode(response.data) : response.data;
    final data = (raw['data'] ?? {}) as Map<String, dynamic>;

    int _intOf(dynamic v) =>
        (v is num) ? v.toInt() : (int.tryParse(v?.toString() ?? '') ?? 0);

    final gold       = _intOf(data['gold'] ?? 0);
    final vipExpireN = data['vip_expire'];
    final vipExpire  = (vipExpireN == null) ? null
        : ((vipExpireN is num) ? vipExpireN.toInt()
        : int.tryParse('$vipExpireN'));

    final inviteNum   = _intOf(data['invite_num'] ?? 0);
    final totalIncome = _intOf(data['total_income'] ?? 0);
    final cashAmount  = _intOf(data['amount'] ?? 0);

    return (
    gold: gold,
    vipExpire: vipExpire,
    inviteNum: inviteNum,
    totalIncome: totalIncome,
    cashAmount: cashAmount,
    );
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

  /// 充值明細
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


  /// 提現
  Future<void> withdraw({
    required String account,
    required int amount,        // 後端範例是整數 10
    required String bankCode,   // 例如: paypal / bank 等
    required String cardName,   // 後端欄位叫 card_name（目前用「提現戶名」傳）
  }) async {
    final payload = {
      "account": account,
      "amount": amount,
      "bank_code": bankCode,
      "card_name": cardName,
    };

    final resp = await _api.post(ApiEndpoints.withdraw, data: payload);

    // 預期回傳：{"code":200,"message":"success","data":null}
    if (resp.statusCode != 200) {
      debugPrint('Network error: ${resp.statusCode}');
      throw Exception('提現申請失敗, 請聯絡客服');
    }
    final data = resp.data;
    if (data is Map && data['code'] == 200) return;

    final msg = (data is Map ? data['message'] : null) ?? 'Withdraw failed';
    debugPrint('msg: $msg');
    throw Exception('提現申請失敗, 請聯絡客服');
  }

  /// 取得提現列表（分頁）
  Future<List<WithdrawRecord>> fetchWithdrawList({required int page}) async {
    final resp = await _api.post(ApiEndpoints.withdrawList, data: {'page': page});
    final raw = resp.data is String ? jsonDecode(resp.data) : resp.data;

    // 只在 code 非 200 時丟錯
    if (raw is! Map || raw['code'] != 200) {
      debugPrint('資料取回有誤 : $raw');
      throw Exception('資料取回有誤, 請聯絡管理員');
    }

    final data = raw['data'];
    if (data == null) return <WithdrawRecord>[];

    final listAny = (data is Map) ? data['list'] : null;
    if (listAny is! List) return <WithdrawRecord>[];

    return listAny.map<WithdrawRecord>((e) {
      return WithdrawRecord.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList();
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

final walletBalanceProvider = FutureProvider<({
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
      gold:        w.gold,
      vipExpire:   w.vipExpire,
      inviteNum:   w.inviteNum,
      totalIncome: w.totalIncome,
      cashAmount:  w.cashAmount,
    ),
    orElse: () => user,
  );
});

final coinPacketsProvider = FutureProvider<List<CoinPacket>>((ref) async {
  final repo = ref.read(walletRepositoryProvider);
  return repo.fetchCoinPackets(page: 1);
});


