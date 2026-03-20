import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';
import 'package:mikomi/core/models/comment_item.dart';

class BangumiTeasing {
  final DioClient _dioClient = DioClient();

  Future<List<CommentItem>> getBangumiComments(
    int id, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final url = ApiConstants.formatUrl(
        '${ApiConstants.bangumiApiNextDomain}/p1/subjects/{0}/comments',
        [id],
      );

      final response = await _dioClient.get(
        url,
        queryParameters: {'limit': limit, 'offset': offset},
      );

      final data = response.data as Map<String, dynamic>;
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
