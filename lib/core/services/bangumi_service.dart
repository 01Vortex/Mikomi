import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/core/utils/recommendation_algorithm.dart';

class BangumiService {
  final DioClient _dioClient = DioClient();

  Future<List<BangumiItem>> getTrendsList({
    int type = 2,
    int limit = 24,
    int offset = 0,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.bangumiApiNextDomain + ApiConstants.bangumiTrends,
        queryParameters: {'type': type, 'limit': limit, 'offset': offset},
      );

      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((item) => BangumiItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<BangumiItem>> getRecommendedList({
    int limit = 12,
    int offset = 0,
  }) async {
    try {
      final fetchLimit = limit * 2;

      final response = await _dioClient.get(
        ApiConstants.bangumiApiNextDomain + ApiConstants.bangumiTrends,
        queryParameters: {'type': 2, 'limit': fetchLimit, 'offset': offset},
      );

      final List<dynamic> data = response.data['data'] ?? [];
      final items = data.map((item) => BangumiItem.fromJson(item)).toList();

      final filteredItems = RecommendationAlgorithm.filterByUpdateTime(
        items,
        maxDaysAgo: 365,
      );

      final sortedItems = RecommendationAlgorithm.sortByRecommendation(
        filteredItems,
      );

      return sortedItems.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<List<BangumiItem>>> getCalendar() async {
    try {
      final response = await _dioClient.get(
        ApiConstants.bangumiApiNextDomain + ApiConstants.bangumiCalendar,
      );

      List<List<BangumiItem>> calendar = [];
      final jsonData = response.data;

      for (int i = 1; i <= 7; i++) {
        List<BangumiItem> dayList = [];
        final jsonList = jsonData['$i'] ?? [];
        for (dynamic jsonItem in jsonList) {
          try {
            dayList.add(BangumiItem.fromJson(jsonItem));
          } catch (_) {}
        }
        calendar.add(dayList);
      }

      return calendar;
    } catch (e) {
      return List.generate(7, (_) => <BangumiItem>[]);
    }
  }

  Future<List<BangumiItem>> searchBangumi(
    String keyword, {
    int offset = 0,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.bangumiApiDomain}${ApiConstants.bangumiSearch}?limit=20&offset=$offset',
        data: {
          'keyword': keyword,
          'sort': 'rank',
          'filter': {
            'type': [2],
            'tag': ['日本'],
            'rank': ['>0', '<=99999'],
            'nsfw': false,
          },
        },
      );

      final List<dynamic> data = response.data['data'] ?? [];
      return data.map((item) => BangumiItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }
}
