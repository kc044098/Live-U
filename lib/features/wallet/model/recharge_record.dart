class RechargeRecord {
  final int id;
  final int gold;          // 充值金幣
  final num amount;        // 充值法幣金額（若後端有用到）
  final int createAt;      // 秒級時間戳（後端若回 0 則顯示 - ）
  final int flag;          // 後端自用
  final int status;        // 2=成功（依你樣本）
  final String orderNumber;
  final String remark;
  final String channelCode;

  const RechargeRecord({
    required this.id,
    required this.gold,
    required this.amount,
    required this.createAt,
    required this.flag,
    required this.status,
    required this.orderNumber,
    required this.remark,
    required this.channelCode,
  });

  factory RechargeRecord.fromJson(Map<String, dynamic> json) {
    return RechargeRecord(
      id: (json['id'] ?? 0) is num ? (json['id'] as num).toInt() : 0,
      gold: (json['gold'] ?? 0) is num ? (json['gold'] as num).toInt() : 0,
      amount: (json['amount'] ?? 0) as num,
      createAt: (json['create_at'] ?? 0) is num ? (json['create_at'] as num).toInt() : 0,
      flag: (json['flag'] ?? 0) is num ? (json['flag'] as num).toInt() : 0,
      status: (json['status'] ?? 0) is num ? (json['status'] as num).toInt() : 0,
      orderNumber: (json['order_number'] ?? '').toString(),
      remark: (json['remark'] ?? '').toString(),
      channelCode: (json['channel_code'] ?? '').toString(),
    );
  }
}