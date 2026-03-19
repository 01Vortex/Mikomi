import 'package:mikomi/core/models/comment_item.dart';

abstract class CommentRepository {
  Future<List<CommentItem>> getBangumiComments(
    int id, {
    int limit = 20,
    int offset = 0,
  });
}
