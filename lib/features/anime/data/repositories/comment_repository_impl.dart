import 'package:mikomi/core/models/comment_item.dart';
import 'package:mikomi/features/anime/data/datasources/comment_remote_datasource.dart';
import 'package:mikomi/features/anime/domain/repositories/comment_repository.dart';

class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource _remoteDataSource;

  CommentRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<CommentItem>> getBangumiComments(
    int id, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await _remoteDataSource.getBangumiComments(
        id,
        limit: limit,
        offset: offset,
      );

      final commentsList = data['data'] as List?;
      if (commentsList == null || commentsList.isEmpty) {
        return [];
      }

      final comments = <CommentItem>[];
      for (var item in commentsList) {
        try {
          if (item is Map) {
            comments.add(CommentItem.fromJson(Map<String, dynamic>.from(item)));
          }
        } catch (e) {
          // 跳过解析失败的项
        }
      }
      return comments;
    } catch (e) {
      return [];
    }
  }
}
