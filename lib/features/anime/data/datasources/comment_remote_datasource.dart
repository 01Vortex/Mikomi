import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';

abstract class CommentRemoteDataSource {
  Future<Map<String, dynamic>> getBangumiComments(
    int id, {
    int limit = 20,
    int offset = 0,
  });
}

class CommentRemoteDataSourceImpl implements CommentRemoteDataSource {
  final DioClient _dioClient;

  CommentRemoteDataSourceImpl(this._dioClient);

  @override
  Future<Map<String, dynamic>> getBangumiComments(
    int id, {
    int limit = 20,
    int offset = 0,
  }) async {
    final url = ApiConstants.formatUrl(
      '${ApiConstants.bangumiApiNextDomain}/p1/subjects/{0}/comments',
      [id],
    );

    final response = await _dioClient.get(
      url,
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return response.data as Map<String, dynamic>;
  }
}
