class UserAvatar {
  final String small;
  final String medium;
  final String large;

  UserAvatar({required this.small, required this.medium, required this.large});

  factory UserAvatar.fromJson(Map<String, dynamic> json) {
    return UserAvatar(
      small: json['small'] as String? ?? '',
      medium: json['medium'] as String? ?? '',
      large: json['large'] as String? ?? '',
    );
  }
}

class User {
  final int id;
  final String username;
  final String nickname;
  final UserAvatar avatar;

  User({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatar: UserAvatar.fromJson(
        json['avatar'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
