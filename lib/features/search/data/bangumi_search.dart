import 'package:flutter/foundation.dart';
import 'package:mikomi/core/models/anime.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';
import 'package:mikomi/features/search/service/search_service.dart';

class BangumiSearch {
  final DioClient _dioClient = DioClient();

  Future<List<Anime>> search(String keyword) async {
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
      final items = data.map((item) => Anime.fromJson(item)).toList();

      final sortedItems = SearchService.sortByRelevance(items, keyword);
      final filteredItems = SearchService.filterByRelevance(
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
