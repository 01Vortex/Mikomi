import 'dart:math' as math;
import 'package:mikomi/core/models/bangumi_item.dart';

class RecommendationAlgorithm {
  /// 推荐排序算法
  /// 使用时间衰减机制，避免高分老番长期霸榜
  static List<BangumiItem> sortByRecommendation(List<BangumiItem> items) {
    final scoredItems = items.map((item) {
      double score = _calculateRecommendationScore(item);
      return MapEntry(item, score);
    }).toList();

    scoredItems.sort((a, b) => b.value.compareTo(a.value));

    return scoredItems.map((e) => e.key).toList();
  }

  /// 计算推荐分数
  /// 使用指数衰减，让新番有更高曝光
  static double _calculateRecommendationScore(BangumiItem item) {
    // 基础质量分 (0-100)
    double qualityScore = _calculateQualityScore(item);

    // 时间衰减系数 (0-1)
    double timeDecay = _calculateTimeDecay(item.airDate);

    // 最终分数 = 质量分 × (0.3 + 时间衰减 × 0.7)
    // 这样新番权重更高，但经典老番仍有30%的基础权重
    double finalScore = qualityScore * (0.3 + timeDecay * 0.7);

    return finalScore;
  }

  /// 计算基础质量分
  static double _calculateQualityScore(BangumiItem item) {
    // 评分分数 (0-10分 -> 0-100分)
    double scoreValue = (item.ratingScore / 10.0) * 100;

    // 排名分数 (使用对数函数平滑差异)
    double rankValue = 0;
    if (item.rank > 0) {
      // rank=1 -> 100分, rank=100 -> 70分, rank=1000 -> 50分
      rankValue = math.max(0, 100 - (math.log(item.rank) / math.log(10)) * 15);
    }

    // 质量分 = 评分65% + 排名35%
    return scoreValue * 0.65 + rankValue * 0.35;
  }

  /// 计算时间衰减系数
  /// 半衰期120天（4个月）
  static double _calculateTimeDecay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 0.2;

    try {
      DateTime date = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      int daysDiff = now.difference(date).inDays;

      // 使用指数衰减，半衰期120天
      const double halfLife = 120.0;
      double decay = math.pow(0.5, daysDiff / halfLife).toDouble();

      // 最小值0.15，确保经典番剧不会完全消失
      return math.max(0.15, decay);
    } catch (e) {
      return 0.2;
    }
  }

  /// 按更新时间筛选
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

  /// 获取最近更新
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

  /// 获取高分番剧
  static List<BangumiItem> getHighRated(
    List<BangumiItem> items, {
    double minScore = 7.0,
  }) {
    return items.where((item) => item.ratingScore >= minScore).toList()
      ..sort((a, b) => b.ratingScore.compareTo(a.ratingScore));
  }
}
