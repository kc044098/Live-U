class InviteUserItem {
  final int id;
  final int uid;
  final int inviteUid;
  final String nickName;
  final List<String> avatar;   // 可能是相對/絕對路徑
  final String inviteCode;
  final int createAt;          // Unix 秒

  InviteUserItem({
    required this.id,
    required this.uid,
    required this.inviteUid,
    required this.nickName,
    required this.avatar,
    required this.inviteCode,
    required this.createAt,
  });

  factory InviteUserItem.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse('${v}') ?? 0;

    return InviteUserItem(
      id: _asInt(json['id']),
      uid: _asInt(json['uid']),
      inviteUid: _asInt(json['invite_uid']),
      nickName: (json['nick_name'] ?? '').toString(),
      avatar: (json['avatar'] is List)
          ? (json['avatar'] as List).map((e) => e.toString()).toList()
          : const <String>[],
      inviteCode: (json['invite_code'] ?? '').toString(),
      createAt: _asInt(json['create_at']),
    );
  }
}

class InviteUserPage {
  final List<InviteUserItem> list;
  final int count; // 後端回傳的統計（可當總數，也可僅參考）

  InviteUserPage({required this.list, required this.count});
}
