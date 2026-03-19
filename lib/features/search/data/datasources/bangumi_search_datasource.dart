import 'package:flutter/foundation.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';
import 'package:mikomi/core/utils/search_algorithm.dart';
import 'package:mikomi/features/search/data/datasources/search_datasource.dart';

class BangumiSearchDatasource implements SearchDatasource {
  final DioClient _dioClient = DioClient();

  @override
  String get sourceName => 'Bangumi';

  @override
  int get priority => 1;

  @override
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
      debugPrint('[$sourceName] 搜索失败: $e');
      rethrow;
    }
  }
}
