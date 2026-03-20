import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/core/utils/recommendation_algorithm.dart';

class BangumiBasis {
  final DioClient _dioClient = DioClient();

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
            final subjectData = jsonItem['subject'] ?? jsonItem;
            dayList.add(BangumiItem.fromJson(subjectData));
          } catch (e) {
            // 忽略解析失败的项
          }
        }
        calendar.add(dayList);
      }

      return calendar;
    } catch (e) {
      return List.generate(7, (_) => <BangumiItem>[]);
    }
  }
}
