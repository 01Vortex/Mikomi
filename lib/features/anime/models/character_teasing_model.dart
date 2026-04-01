import 'package:mikomi/core/models/comment.dart';
import 'package:mikomi/core/models/user.dart';

class CharacterTeasingModel extends Comment {
  final List<CharacterTeasingModel> replies;

  CharacterTeasingModel({
    required super.user,
    required super.content,
    required super.createdAt,
    this.replies = const [],
  });

  factory CharacterTeasingModel.fromJson(Map<String, dynamic> json) {
    final repliesList = json['replies'] as List<dynamic>? ?? [];
    return CharacterTeasingModel(
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] as int? ?? 0,
      replies: repliesList
          .map(
            (item) => CharacterTeasingModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
