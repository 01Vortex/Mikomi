import 'package:mikomi/core/models/comment.dart';
import 'package:mikomi/core/models/user.dart';

class AnimeTeasingModel extends Comment {
  final int rate;
  final int updatedAt;

  AnimeTeasingModel({
    required super.user,
    required super.content,
    required super.createdAt,
    required this.rate,
    required this.updatedAt,
  });

  factory AnimeTeasingModel.fromJson(Map<String, dynamic> json, User user) {
    return AnimeTeasingModel(
      user: user,
      content: json['comment'] as String? ?? '',
      createdAt: json['updatedAt'] as int? ?? 0,
      rate: json['rate'] as int? ?? 0,
      updatedAt: json['updatedAt'] as int? ?? 0,
    );
  }
}

class CommentItem {
  final User user;
  final AnimeTeasingModel comment;

  CommentItem({required this.user, required this.comment});

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json['user'] as Map<String, dynamic>? ?? {});
    return CommentItem(
      user: user,
      comment: AnimeTeasingModel.fromJson(json, user),
    );
  }
}
