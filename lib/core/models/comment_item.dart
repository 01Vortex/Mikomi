class UserAvatar {
  final String small;
  final String medium;
  final String large;

  UserAvatar({required this.small, required this.medium, required this.large});

  factory UserAvatar.fromJson(Map<String, dynamic> json) {
    return UserAvatar(
      small: json['small'] ?? '',
      medium: json['medium'] ?? '',
      large: json['large'] ?? '',
    );
  }
}

class User {
  final int id;
  final String username;
  final String nickname;
  final UserAvatar avatar;
  final String sign;
  final int joinedAt;

  User({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
    required this.sign,
    required this.joinedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
      avatar: UserAvatar.fromJson(json['avatar'] as Map<String, dynamic>),
      sign: json['sign'] ?? '',
      joinedAt: json['joinedAt'] ?? 0,
    );
  }
}

class Comment {
  final int rate;
  final String comment;
  final int updatedAt;

  Comment({required this.rate, required this.comment, required this.updatedAt});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      rate: json['rate'] ?? 0,
      comment: json['comment'] ?? '',
      updatedAt: json['updatedAt'] ?? 0,
    );
  }
}

class CommentItem {
  final User user;
  final Comment comment;

  CommentItem({required this.user, required this.comment});

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      user: User.fromJson(json['user']),
      comment: Comment.fromJson(json),
    );
  }
}
