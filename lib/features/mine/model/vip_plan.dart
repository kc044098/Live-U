class VipPlan {
  final int id;
  final String title;     // "1个月" / "3个月"
  final double price;     // 原價
  final double realPrice; // 特價（0 表無）
  final String content;
  final int sort;
  final int month;

  final String productId;

  VipPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.realPrice,
    required this.content,
    required this.sort,
    required this.month,
    this.productId = '',        // 預設容錯
  });

  factory VipPlan.fromJson(Map<String, dynamic> j) {
    double _d(v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;
    String _s(v) => (v ?? '').toString();

    return VipPlan(
      id: j['id'] ?? 0,
      title: _s(j['title']),
      price: _d(j['price']),
      realPrice: _d(j['real_price'] ?? j['realPrice']),
      content: _s(j['content']),
      sort: j['sort'] ?? 0,
      month: j['month'] ?? 0,
      productId: _s(j['product_id'] ?? j['productId']),
    );
  }

  double get payPrice => realPrice > 0 ? realPrice : price;
  double get perMonth => month > 0 ? payPrice / month : payPrice;
}
