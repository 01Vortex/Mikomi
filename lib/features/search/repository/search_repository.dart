import 'package:mikomi/core/data/datasources/bangumi_source.dart';
import 'package:mikomi/core/models/anime.dart';
import 'package:mikomi/features/search/service/hot_search_service.dart';
import 'package:mikomi/features/search/service/search_algorithm_service.dart';

class SearchRepository {
  final BangumiSource _bangumiSource;

  SearchRepository({BangumiSource? bangumiSource})
    : _bangumiSource = bangumiSource ?? BangumiSource();

  Future<List<Anime>> searchSuggestions(String keyword) async {
    try {
      final normalizedKeyword = keyword.trim();
      if (normalizedKeyword.isEmpty) return [];

      final data = await _bangumiSource.searchSubjects(
        keyword: normalizedKeyword,
        limit: 30,
        sort: 'match',
      );
      final items = data
          .whereType<Map>()
          .map((item) => Anime.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.id > 0)
          .where((item) => _matchesSuggestion(item, normalizedKeyword))
          .toList();

      final sortedItems = SearchAlgorithmService.sortByRelevance(
        items,
        normalizedKeyword,
      );

      return sortedItems.take(10).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Anime>> search(String keyword) async {
    try {
      final normalizedKeyword = keyword.trim();
      if (normalizedKeyword.isEmpty) return [];

      final sorts = normalizedKeyword.length <= 2
          ? const ['heat', 'rank']
          : const ['match', 'heat'];
      final responses = await Future.wait(
        sorts.map(
          (sort) => _bangumiSource.searchSubjects(
            keyword: normalizedKeyword,
            limit: 50,
            sort: sort,
          ),
        ),
      );

      final itemMap = <int, Anime>{};
      for (final data in responses) {
        final items = data
            .whereType<Map>()
            .map((item) => Anime.fromJson(Map<String, dynamic>.from(item)))
            .where((item) => item.id > 0)
            .toList();

        for (final item in items) {
          itemMap[item.id] = item;
        }
      }

      final sortedItems = SearchAlgorithmService.sortByRelevance(
        itemMap.values.toList(),
        normalizedKeyword,
      );
      final filteredItems = SearchAlgorithmService.filterByRelevance(
        sortedItems,
        normalizedKeyword,
        minScore: normalizedKeyword.length <= 2 ? 12 : 20,
      );

      return filteredItems.take(20).toList();
    } catch (_) {
      return [];
    }
  }

  bool _matchesSuggestion(Anime item, String keyword) {
    final normalizedKeyword = _normalizeSearchText(keyword);
    if (normalizedKeyword.isEmpty) return false;

    return _normalizeSearchText(item.displayName).contains(normalizedKeyword) ||
        _normalizeSearchText(item.nameCn).contains(normalizedKeyword) ||
        _normalizeSearchText(item.name).contains(normalizedKeyword);
  }

  String _normalizeSearchText(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[·•・:：\-—_!！?？,，.。/\\\(\)\[\]【】《》「」『』~～]'), '');
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
