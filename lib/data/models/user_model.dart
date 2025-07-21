class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoURL;
  final String? idToken;
  final String? isBroadcaster;
  bool? isVip;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoURL,
    this.idToken,
    this.isBroadcaster,
    this.isVip,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'idToken': idToken,
      'isBroadcaster': isBroadcaster,
      'isVip': isVip,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoURL: json['photoURL'] ?? '',
      idToken: json['idToken'] ?? '',
      isBroadcaster: json['isBroadcaster'] ?? '1',
      isVip: json['isVip'] ?? false,
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? idToken,
    String? isBroadcaster,
    bool? isVip,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      idToken: idToken ?? this.idToken,
      isBroadcaster: isBroadcaster ?? this.isBroadcaster,
      isVip: isVip ?? this.isVip,
    );
  }
}