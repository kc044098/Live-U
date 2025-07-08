class UserProfile {
  final String userId;
  final String name;
  final String avatarUrl;

  UserProfile({
    required this.userId,
    required this.name,
    required this.avatarUrl,
  });

  UserProfile copyWith({String? name, String? avatarUrl}) {
    return UserProfile(
      userId: userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      name: json['name'],
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'avatarUrl': avatarUrl,
  };
}