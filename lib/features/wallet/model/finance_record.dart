class FinanceRecord {
  final int id;
  final int gold;
  final int flag;
  final int createAt;   // 秒
  final int oId;
  final int roomId;
  final int uid;
  final String nickName;
  final String title;

  // 後端可能回 String 或 List<String>，這裡統一成陣列
  final List<String> avatarList;

  // 方便沿用既有 r.avatar 寫法：取第一張（無則 null）
  String? get avatar => avatarList.isNotEmpty ? avatarList.first : null;

  FinanceRecord({
    required this.id,
    required this.gold,
    required this.flag,
    required this.createAt,
    required this.oId,
    required this.roomId,
    required this.uid,
    required this.nickName,
    required this.title,
    required this.avatarList,
  });

  factory FinanceRecord.fromJson(Map<String, dynamic> j) {
    final raw = j['avatar'];
    List<String> avatars = [];
    if (raw is String) {
      if (raw.isNotEmpty) avatars = [raw];
    } else if (raw is List) {
      avatars = raw.map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return FinanceRecord(
      id: j['id'] ?? 0,
      gold: j['gold'] ?? 0,
      flag: j['flag'] ?? 0,
      createAt: j['create_at'] ?? 0,
      oId: j['o_id'] ?? 0,
      roomId: j['room_id'] ?? 0,
      uid: j['uid'] ?? 0,
      nickName: (j['nick_name'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      avatarList: avatars,
    );
  }
}

