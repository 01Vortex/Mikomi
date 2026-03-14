class PersonComment {
  final User user;
  final String content;
  final int createdAt;
  final List<PersonComment> replies;

  PersonComment({
    required this.user,
    required this.content,
    required this.createdAt,
    this.replies = const [],
  });

  factory PersonComment.fromJson(Map<String, dynamic> json) {
    final repliesList = json['replies'] as List<dynamic>? ?? [];
    return PersonComment(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] as int? ?? 0,
      replies: repliesList
          .map((item) => PersonComment.fromJson(item as Map<String, dynamic>))
          .toList(),
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
