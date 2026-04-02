import 'package:mikomi/core/data/datasources/bangumi_source.dart';
import 'package:mikomi/core/models/anime.dart';
import 'package:mikomi/features/search/service/hot_search_service.dart';
import 'package:mikomi/features/search/service/search_service.dart';

class SearchRepository {
  final BangumiSource _bangumiSource;

  SearchRepository({BangumiSource? bangumiSource})
    : _bangumiSource = bangumiSource ?? BangumiSource();

  Future<List<Anime>> search(String keyword) async {
    try {
      final data = await _bangumiSource.searchSubjects(keyword: keyword, limit: 50);
      final items = data
          .whereType<Map>()
          .map((item) => Anime.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      final sortedItems = SearchService.sortByRelevance(items, keyword);
      final filteredItems = SearchService.filterByRelevance(
        sortedItems,
        keyword,
        minScore: 30,
      );

      return filteredItems.take(20).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Anime>> getPopularityRankings({int limit = 10}) async {
    try {
      final data = await _bangumiSource.fetchTrends(limit: 50, offset: 0);
      final items = data
          .whereType<Map>()
          .map((item) => Anime.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      return HotSearchService.getPopularityRanking(items, limit: limit);
    } catch (_) {
      return [];
    }
  }
}
