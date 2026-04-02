import 'package:mikomi/core/data/datasources/bangumi_source.dart';
import 'package:mikomi/core/models/anime.dart';
import 'package:mikomi/features/search/service/hot_search_service.dart';
import 'package:mikomi/features/search/service/search_algorithm_service.dart';

class SearchService {
  final BangumiSource _bangumiSource;

  SearchService({BangumiSource? bangumiSource})
    : _bangumiSource = bangumiSource ?? BangumiSource();

  Future<List<Anime>> search(String keyword) async {
    try {
      final data = await _bangumiSource.searchSubjects(keyword: keyword, limit: 50);
      final items = data
          .whereType<Map>()
          .map((item) => Anime.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      final sortedItems = SearchAlgorithmService.sortByRelevance(items, keyword);
      final filteredItems = SearchAlgorithmService.filterByRelevance(
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

      return HotSearchAlgorithmService.getPopularityRanking(items, limit: limit);
    } catch (_) {
      return [];
    }
  }
}
