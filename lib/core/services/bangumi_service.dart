import 'package:flutter/foundation.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/core/network/api_constants.dart';
import 'package:mikomi/core/models/anime.dart';
import 'package:mikomi/features/search/service/search_service.dart';

class BangumiService {
  final DioClient _dioClient = DioClient();

  Future<List<Anime>> getTrendsList({
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
      return data.map((item) => Anime.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Anime>> searchBangumi(
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
      final items = data.map((item) => Anime.fromJson(item)).toList();

      final sortedItems = SearchService.sortByRelevance(items, keyword);

      final filteredItems = SearchService.filterByRelevance(
        sortedItems,
        keyword,
        minScore: 30,
      );

      return filteredItems.take(20).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Anime?> getBangumiById(int id) async {
    try {
      final response = await _dioClient.get(
        '${ApiConstants.bangumiApiDomain}/v0/subjects/$id',
      );

      return Anime.fromJson(response.data);
    } catch (e) {
      debugPrint('获取番剧详情失败: $e');
      return null;
    }
  }
}
