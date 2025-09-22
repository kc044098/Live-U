class WithdrawRecord {
  final int id;
  final int amount;        // 申請金額
  final int realAmount;    // 實到金額
  final int status;        // 1=审核中,2=成功,3=审核拒绝,4=审核通过
  final String account;    // 收款帳號
  final String bankCode;   // paypal / visa / ...
  final String cardName;   // 戶名或卡號識別
  final int createAt;      // Unix 秒
  final String orderNumber; // 提現單號

  WithdrawRecord({
    required this.id,
    required this.amount,
    required this.realAmount,
    required this.status,
    required this.account,
    required this.bankCode,
    required this.cardName,
    required this.createAt,
    this.orderNumber = '',
  });

  factory WithdrawRecord.fromJson(Map<String, dynamic> j) {
    return WithdrawRecord(
      id: (j['id'] ?? 0) as int,
      amount: (j['amount'] ?? 0),
      realAmount: (j['real_amount'] ?? 0),
      status: (j['status'] ?? 0) as int,
      account: (j['account'] ?? '').toString(),
      bankCode: (j['bank_code'] ?? '').toString(),
      cardName: (j['card_name'] ?? '').toString(),
      createAt: (j['create_at'] ?? 0) as int,
      orderNumber: (j['order_number'] ?? '').toString(),
    );
  }
}