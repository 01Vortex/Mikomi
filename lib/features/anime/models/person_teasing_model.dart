import 'package:mikomi/core/models/comment.dart';
import 'package:mikomi/core/models/user.dart';

class PersonTeasingModel extends Comment {
  final List<PersonTeasingModel> replies;

  PersonTeasingModel({
    required super.user,
    required super.content,
    required super.createdAt,
    this.replies = const [],
  });

  factory PersonTeasingModel.fromJson(Map<String, dynamic> json) {
    final repliesList = json['replies'] as List<dynamic>? ?? [];
    return PersonTeasingModel(
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] as int? ?? 0,
      replies: repliesList
          .map((item) => PersonTeasingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
