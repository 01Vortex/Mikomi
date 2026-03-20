import 'package:flutter/foundation.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
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
            'rank': ['>0', '<=99999'],
            'nsfw': false,
          },
        },
      );

      final List<dynamic> data = response.data['data'] ?? [];
      final items = data.map((item) => BangumiItem.fromJson(item)).toList();

      final sortedItems = SearchAlgorithm.sortByRelevance(items, keyword);

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
