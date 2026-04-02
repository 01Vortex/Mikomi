import 'package:mikomi/core/network/app_api.dart';
import 'package:mikomi/core/network/dio_client.dart';

class BangumiSource {
  final DioClient _dioClient = DioClient();

  Future<List<dynamic>> fetchTrends({
    required int limit,
    required int offset,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.bangumiApiNextDomain + ApiConstants.bangumiTrends,
      queryParameters: {'type': 2, 'limit': limit, 'offset': offset},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['data'] as List?)?.cast<dynamic>() ?? [];
    }
    return [];
  }

  Future<List<dynamic>> searchSubjects({
    required String keyword,
    int limit = 48,
    int offset = 0,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.bangumiApiDomain + ApiConstants.bangumiSearch,
      data: {
        'keyword': keyword,
        'sort': 'rank',
        'filter': {'type': [2]},
      },
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['data'] as List?)?.cast<dynamic>() ?? [];
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchCalendar() async {
    final response = await _dioClient.get(
      ApiConstants.bangumiApiNextDomain + ApiConstants.bangumiCalendar,
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
