import 'dart:io' show Platform;

class VipPlan {
  final int id;
  final String title;
  final double price;
  final double realPrice;
  final String content;
  final int sort;
  final int month;

  final String googleId;
  final String appleId;

  // 👇 新增：Android base plan id（用來找 offer）
  final String androidBasePlanId;

  VipPlan({
    required this.id,
    required this.title,
    required this.price,
    required this.realPrice,
    required this.content,
    required this.sort,
    required this.month,
    this.googleId = '',
    this.appleId = '',
    this.androidBasePlanId = '',
  });

  factory VipPlan.fromJson(Map<String, dynamic> j) {
    double _d(v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;
    String _s(v) => (v ?? '').toString();

    // 若後端沒給 base plan id，就依月份猜
    String _bpByMonth(int m) {
      switch (m) {
        case 1:  return 'vip1m';
        case 3:  return 'vip3m';
        case 6:  return 'vip6m';
        case 12: return 'vip12months';
        default: return 'vip1m';
      }
    }

    final month = j['month'] ?? 0;

    return VipPlan(
      id: j['id'] ?? 0,
      title: _s(j['title']),
      price: _d(j['price']),
      realPrice: _d(j['real_price'] ?? j['realPrice']),
      content: _s(j['content']),
      sort: j['sort'] ?? 0,
      month: month,
      googleId: _s(j['google_id'] ?? j['googleId'] ?? j['android_product_id']),
      appleId : _s(j['apple_id']  ?? j['appleId']  ?? j['ios_product_id']),
      androidBasePlanId: _s(j['android_base_plan_id'] ?? j['base_plan_id'] ?? _bpByMonth(month)),
    );
  }

  double get payPrice => realPrice > 0 ? realPrice : price;
  double get perMonth => month > 0 ? payPrice / month : payPrice;

  String get storeProductId => Platform.isAndroid ? googleId : appleId;
}

