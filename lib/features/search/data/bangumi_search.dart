import 'package:flutter/foundation.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';
import 'package:mikomi/core/utils/search_algorithm.dart';

class BangumiSearch {
  final DioClient _dioClient = DioClient();

  Future<List<BangumiItem>> search(String keyword) async {
    try {
      final response = await _dioClient
          .post(
            '${ApiConstants.bangumiApiDomain}${ApiConstants.bangumiSearch}?limit=50&offset=0',
            data: {
              'keyword': keyword,
              'sort': 'rank',
              'filter': {
                'type': [2],
                'rank': ['>0', '<=99999'],
                'nsfw': false,
              },
            },
          )
          .timeout(const Duration(seconds: 10));

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
      debugPrint('[Bangumi搜索] 失败: $e');
      rethrow;
    }
  }
}
