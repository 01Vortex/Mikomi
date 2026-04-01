import 'package:mikomi/core/models/user.dart';

class Comment {
  final User user;
  final String content;
  final int createdAt;

  Comment({
    required this.user,
    required this.content,
    required this.createdAt,
  });
}
