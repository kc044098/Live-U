class VipPlan {
  final int id;
  final String title;     // "1个月" / "3个月" / ...
  final double price;     // 原價
  final double realPrice; // 特價（0 代表無特價）
  final String content;
  final int sort;
  final int month;

  VipPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.realPrice,
    required this.content,
    required this.sort,
    required this.month,
  });

  factory VipPlan.fromJson(Map<String, dynamic> j) {
    double _toDouble(v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;
    return VipPlan(
      id: j['id'] ?? 0,
      title: j['title'] ?? '',
      price: _toDouble(j['price']),
      realPrice: _toDouble(j['real_price']),
      content: j['content'] ?? '',
      sort: j['sort'] ?? 0,
      month: j['month'] ?? 0,
    );
  }

  /// 付款金額：若有特價用 realPrice，否則用原價 price
  double get payPrice => realPrice > 0 ? realPrice : price;

  /// 每月單價：用 (realPrice 或 price) / month
  double get perMonth => month > 0 ? payPrice / month : payPrice;
}
