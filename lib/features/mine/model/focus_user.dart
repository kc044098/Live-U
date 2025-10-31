class MemberFocusPage {
  final List<MemberFocusUser> list;
  final int count;
  MemberFocusPage({required this.list, required this.count});
}

class MemberFocusUser {
  final int id;
  final String name;           // nick_name
  final List<String> avatars;  // avatar (server-relative or http)
  final List<String> tags;

  MemberFocusUser({
    required this.id,
    required this.name,
    required this.avatars,
    required this.tags,
  });

  factory MemberFocusUser.fromJson(Map<String, dynamic> json) {
    return MemberFocusUser(
      id: (json['id'] ?? 0) as int,
      name: (json['nick_name'] ?? '').toString(),
      avatars: (json['avatar'] is List)
          ? (json['avatar'] as List).map((e) => e.toString()).toList()
          : const [],
      tags: (json['tags'] is List)
          ? (json['tags'] as List).map((e) => e.toString()).toList()
          : const [],
    );
  }
}
