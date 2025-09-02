class WalletInfo {
  final int gold;
  final num amount;
  final num totalGold;
  final num totalIncome;
  final num totalConsume;
  final num totalWithdraw;
  final int inviteNum;
  final int pid;
  final int createAt;
  final int updateAt;
  final int vipExpire;

  WalletInfo({
    required this.gold,
    required this.amount,
    required this.totalGold,
    required this.totalIncome,
    required this.totalConsume,
    required this.totalWithdraw,
    required this.inviteNum,
    required this.pid,
    required this.createAt,
    required this.updateAt,
    required this.vipExpire,
  });

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    return WalletInfo(
      gold: (json['gold'] ?? 0) as int,
      amount: json['amount'] ?? 0,
      totalGold: json['total_gold'] ?? 0,
      totalIncome: json['total_income'] ?? 0,
      totalConsume: json['total_consume'] ?? 0,
      totalWithdraw: json['total_withdraw'] ?? 0,
      inviteNum: json['invite_num'] ?? 0,
      pid: json['pid'] ?? 0,
      createAt: json['create_at'] ?? 0,
      updateAt: json['update_at'] ?? 0,
      vipExpire: json['vip_expire'] ?? 0,
    );
  }
}
