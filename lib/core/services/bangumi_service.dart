import 'package:flutter/foundation.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/core/utils/recommendation_algorithm.dart';
import 'package:mikomi/core/utils/search_algorithm.dart';

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
      debugPrint('开始获取每周时间表...');
      final response = await _dioClient.get(
        ApiConstants.bangumiApiNextDomain + ApiConstants.bangumiCalendar,
      );

      debugPrint('时间表API响应状态: ${response.statusCode}');

      List<List<BangumiItem>> calendar = [];
      final jsonData = response.data;

      for (int i = 1; i <= 7; i++) {
        List<BangumiItem> dayList = [];
        final jsonList = jsonData['$i'] ?? [];
        debugPrint('第$i天原始数据: ${jsonList.length}条');
        for (dynamic jsonItem in jsonList) {
          try {
            // Calendar API返回的数据结构中，番剧信息在subject字段中
            final subjectData = jsonItem['subject'] ?? jsonItem;
            dayList.add(BangumiItem.fromJson(subjectData));
          } catch (e) {
            debugPrint('解析番剧数据失败: $e');
          }
        }
        calendar.add(dayList);
      }

      debugPrint('成功获取时间表，共${calendar.length}天');
      return calendar;
    } catch (e) {
      debugPrint('获取时间表失败: $e');
      return List.generate(7, (_) => <BangumiItem>[]);
    }
  }

  Future<List<BangumiItem>> searchBangumi(
    String keyword, {
    int offset = 0,
  }) async {
    try {
      final response = await _dioClient.post(
        '${ApiConstants.bangumiApiDomain}${ApiConstants.bangumiSearch}?limit=50&offset=$offset',
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
      final items = data.map((item) => BangumiItem.fromJson(item)).toList();

      // 使用精准搜索算法排序
      final sortedItems = SearchAlgorithm.sortByRelevance(items, keyword);

      // 过滤低相关度结果
      final filteredItems = SearchAlgorithm.filterByRelevance(
        sortedItems,
        keyword,
        minScore: 30,
      );

      return filteredItems.take(20).toList();
    } catch (e) {
      return [];
    }
  }

  Future<BangumiItem?> getBangumiById(int id) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.bangumiApiDomain}/v0/subjects/$id',
      );

      return BangumiItem.fromJson(response.data);
    } catch (e) {
      debugPrint('获取番剧详情失败: $e');
      return null;
    }
  }
}
