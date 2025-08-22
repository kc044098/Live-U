// models/fan_user_model.dart

class MemberFansPage {
  final List<MemberFanUser> list;
  final int count;
  MemberFansPage({required this.list, required this.count});
}

class MemberFanUser {
  final int id;
  final String name;           // nick_name
  final List<String> avatars;  // avatar (server-relative or http)
  final List<String> tags;

  MemberFanUser({
    required this.id,
    required this.name,
    required this.avatars,
    required this.tags,
  });

  factory MemberFanUser.fromJson(Map<String, dynamic> json) {
    return MemberFanUser(
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

extension _JsonX on dynamic {
  Map<String, dynamic> asMap() => (this as Map).cast<String, dynamic>();
}

extension FirstNonEmpty on List<String> {
  String firstNonEmptyOrEmpty() {
    for (final s in this) { if (s.isNotEmpty) return s; }
    return '';
  }
}