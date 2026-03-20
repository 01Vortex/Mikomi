import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/core/utils/recommendation_algorithm.dart';
import 'package:mikomi/features/home/data/datasources/home_remote_datasource.dart';

class HomeRepositoryImpl {
  final HomeRemoteDatasource _remoteDatasource = HomeRemoteDatasource();

  Future<List<BangumiItem>> getRecommendedList({
    int limit = 12,
    int offset = 0,
  }) async {
    try {
      final items = await _remoteDatasource.getRecommendedList(
        limit: limit,
        offset: offset,
      );

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
      return await _remoteDatasource.getCalendar();
    } catch (e) {
      return List.generate(7, (_) => <BangumiItem>[]);
    }
  }
}
