/// The authenticated user, persisted to local storage (mirrors `bb-session`).
class UserModel {
  final String userId;
  final String email;
  final String name;
  final String? avatar;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic> providers;

  const UserModel({
    required this.userId,
    required this.email,
    required this.name,
    this.avatar,
    this.accessToken,
    this.refreshToken,
    this.providers = const {},
  });

  bool get hasGoogle => providers['google'] != null;
  bool get hasFacebook => providers['facebook'] != null;

  UserModel copyWith({
    String? userId,
    String? email,
    String? name,
    String? avatar,
    String? accessToken,
    String? refreshToken,
    Map<String, dynamic>? providers,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      providers: providers ?? this.providers,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'name': name,
        'avatar': avatar,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'providers': providers,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: (json['userId'] as String?) ?? '',
        email: (json['email'] as String?) ?? '',
        name: (json['name'] as String?) ?? '',
        avatar: json['avatar'] as String?,
        accessToken: json['accessToken'] as String?,
        refreshToken: json['refreshToken'] as String?,
        providers: (json['providers'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}
