import 'package:mikomi/core/models/bangumi_item.dart';

class RecommendationAlgorithm {
  static List<BangumiItem> sortByRecommendation(List<BangumiItem> items) {
    final now = DateTime.now();

    final scoredItems = items.map((item) {
      double score = 0.0;

      // 评分权重 (40%)
      if (item.ratingScore > 0) {
        score += (item.ratingScore / 10.0) * 40;
      }

      // 排名权重 (30%)
      if (item.rank > 0) {
        final rankScore = (1000 - item.rank.clamp(0, 1000)) / 1000.0;
        score += rankScore * 30;
      }

      // 时间新鲜度权重 (30%)
      if (item.airDate.isNotEmpty) {
        try {
          final airDate = DateTime.parse(item.airDate);
          final daysDiff = now.difference(airDate).inDays.abs();

          // 最近3个月内的番剧加分
          if (daysDiff <= 90) {
            score += 30;
          } else if (daysDiff <= 180) {
            score += 20;
          } else if (daysDiff <= 365) {
            score += 10;
          }
        } catch (_) {}
      }

      return MapEntry(item, score);
    }).toList();

    scoredItems.sort((a, b) => b.value.compareTo(a.value));

    return scoredItems.map((e) => e.key).toList();
  }

  static List<BangumiItem> filterByUpdateTime(
    List<BangumiItem> items, {
    int maxDaysAgo = 365,
  }) {
    final now = DateTime.now();

    return items.where((item) {
      if (item.airDate.isEmpty) return true;

      try {
        final airDate = DateTime.parse(item.airDate);
        final daysDiff = now.difference(airDate).inDays;
        return daysDiff >= 0 && daysDiff <= maxDaysAgo;
      } catch (_) {
        return true;
      }
    }).toList();
  }

  static List<BangumiItem> getRecentUpdates(List<BangumiItem> items) {
    final now = DateTime.now();

    final recentItems = items.where((item) {
      if (item.airDate.isEmpty) return false;

      try {
        final airDate = DateTime.parse(item.airDate);
        final daysDiff = now.difference(airDate).inDays;
        return daysDiff >= 0 && daysDiff <= 30;
      } catch (_) {
        return false;
      }
    }).toList();

    recentItems.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.airDate);
        final dateB = DateTime.parse(b.airDate);
        return dateB.compareTo(dateA);
      } catch (_) {
        return 0;
      }
    });

    return recentItems;
  }

  static List<BangumiItem> getHighRated(
    List<BangumiItem> items, {
    double minScore = 7.0,
  }) {
    return items.where((item) => item.ratingScore >= minScore).toList()
      ..sort((a, b) => b.ratingScore.compareTo(a.ratingScore));
  }
}
