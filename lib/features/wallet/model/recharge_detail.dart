// model
class RechargeDetail {
  final int id;
  final int gold;            // 充值獲得的金幣
  final double amount;       // 法幣金額
  final String channelCode;  // 支付/通道
  final int createAt;        // 秒級時間戳
  final int status;          // 1處理中 2成功 3失敗
  final String orderNumber;
  final String remark;

  RechargeDetail({
    required this.id,
    required this.gold,
    required this.amount,
    required this.channelCode,
    required this.createAt,
    required this.status,
    required this.orderNumber,
    required this.remark,
  });

  factory RechargeDetail.fromJson(Map<String, dynamic> j) => RechargeDetail(
    id: j['id'] ?? 0,
    gold: j['gold'] ?? 0,
    amount: (j['amount'] is num) ? (j['amount'] as num).toDouble() : double.tryParse('${j['amount']}') ?? 0,
    channelCode: (j['channel_code'] ?? '').toString(),
    createAt: j['create_at'] ?? 0,
    status: j['status'] ?? 0,
    orderNumber: (j['order_number'] ?? '').toString(),
    remark: (j['remark'] ?? '').toString(),
  );
}
