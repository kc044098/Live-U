/// 支援多種登入方式

class LoginMethod {
  final String provider;
  final String identifier;
  final bool isPrimary;
  final String? token;

  LoginMethod({
    required this.provider,
    required this.identifier,
    this.isPrimary = false,
    this.token,
  });

  factory LoginMethod.fromJson(Map<String, dynamic> json) {
    return LoginMethod(
      provider: (json['provider'] ?? '').toString().toLowerCase(), // 👈
      identifier: json['identifier'] ?? '',
      isPrimary: json['isPrimary'] ?? false,
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'identifier': identifier,
    'isPrimary': isPrimary,
    'token': token,
  };

  LoginMethod copyWith({
    String? provider,
    String? identifier,
    bool? isPrimary,
    String? token,
  }) {
    return LoginMethod(
      provider: provider ?? this.provider,
      identifier: identifier ?? this.identifier,
      isPrimary: isPrimary ?? this.isPrimary,
      token: token ?? this.token,
    );
  }

}

