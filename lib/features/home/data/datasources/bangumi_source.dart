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

  Future<Map<String, dynamic>> fetchCalendar() async {
    final response = await _dioClient.get(
      ApiConstants.bangumiApiNextDomain + ApiConstants.bangumiCalendar,
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }
}
