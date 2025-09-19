class RewardItem {
  final int id;
  final int gold;        // 金額（以分為單位，顯示時 /100）
  final int roomId;
  final String nickName;
  final int oId;
  final int gId;
  final String title;
  final int uid;
  final List<String> avatar;
  final int flag;
  final int createAt;    // Unix seconds

  RewardItem({
    required this.id,
    required this.gold,
    required this.roomId,
    required this.nickName,
    required this.oId,
    required this.gId,
    required this.title,
    required this.uid,
    required this.avatar,
    required this.flag,
    required this.createAt,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return RewardItem(
      id: _asInt(json['id']),
      gold: _asInt(json['gold']),
      roomId: _asInt(json['room_id']),
      nickName: (json['nick_name'] ?? '').toString(),
      oId: _asInt(json['o_id']),
      gId: _asInt(json['g_id']),
      title: (json['title'] ?? '').toString(),
      uid: _asInt(json['uid']),
      avatar: (json['avatar'] is List)
          ? (json['avatar'] as List).map((e) => e.toString()).toList()
          : const <String>[],
      flag: _asInt(json['flag']),
      createAt: _asInt(json['create_at']),
    );
  }
}

class RewardPage {
  final List<RewardItem> list;
  final int count;
  RewardPage({required this.list, required this.count});
}