enum UserRole { audience, host, admin }

class UserModel {
  final String userId;
  final String username;
  final UserRole role;

  UserModel({
    required this.userId,
    required this.username,
    required this.role,
  });
}
