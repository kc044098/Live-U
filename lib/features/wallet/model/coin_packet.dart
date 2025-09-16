class CoinPacket {
  final int id;
  final int gold;   // 幣數
  final int price;  // 金額（可能是分/整數，看後端）
  final int bonus;  // 贈送幣

  CoinPacket({
    required this.id,
    required this.gold,
    required this.price,
    required this.bonus,
  });

  factory CoinPacket.fromJson(Map<String, dynamic> j) => CoinPacket(
    id: (j['id'] ?? 0) as int,
    gold: (j['gold'] ?? 0) as int,
    price: (j['price'] ?? 0) as int,
    bonus: (j['bonus'] ?? 0) as int,
  );
}
