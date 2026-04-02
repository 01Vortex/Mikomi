import 'package:mikomi/core/models/comment.dart';
import 'package:mikomi/core/models/user.dart';

class AnimeTeasingModel extends Comment {
  final int score;
  final int updatedAtEpoch;

  AnimeTeasingModel({
    required super.user,
    required super.content,
    required super.createdAt,
    required this.score,
    required this.updatedAtEpoch,
  });

  factory AnimeTeasingModel.fromJson(Map<String, dynamic> json, User user) {
    final timestamp = json['updatedAt'] as int? ?? 0;
    return AnimeTeasingModel(
      user: user,
      content: json['comment'] as String? ?? '',
      createdAt: timestamp,
      score: json['rate'] as int? ?? 0,
      updatedAtEpoch: timestamp,
    );
  }
}

class CommentItem {
  final User user;
  final AnimeTeasingModel feedback;

  CommentItem({required this.user, required this.feedback});

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json['user'] as Map<String, dynamic>? ?? {});
    return CommentItem(user: user, feedback: AnimeTeasingModel.fromJson(json, user));
  }
}
