import 'dart:math' as math;
import 'package:mikomi/core/models/bangumi_item.dart';

class HotSearchService {
  /// 计算番剧热度分数
  /// 优化后的算法，避免高分老番长期霸榜
  /// 综合考虑:
  /// - 基础质量分 (评分 + 排名) (50%)
  /// - 时间衰减 (50%)
  static double calculatePopularityScore(BangumiItem item) {
    // 基础质量分 (0-100)
    double qualityScore = _calculateQualityScore(item);

    // 时间衰减系数 (0-1)
    double timeDecay = _calculateTimeDecay(item.airDate);

    // 最终分数 = 质量分 * 时间衰减
    // 这样即使是高分番剧，随着时间推移也会逐渐下降
    double finalScore = qualityScore * (0.5 + timeDecay * 0.5);

    return finalScore;
  }

  /// 计算基础质量分
  /// 综合评分和排名
  static double _calculateQualityScore(BangumiItem item) {
    // 评分分数 (0-10分 -> 0-100分)
    double scoreValue = (item.ratingScore / 10.0) * 100;

    // 排名分数 (使用对数函数，避免排名差距过大)
    double rankValue = 0;
    if (item.rank > 0) {
      // 使用对数函数平滑排名差异
      // rank=1 -> 100分, rank=100 -> 70分, rank=1000 -> 50分
      rankValue = math.max(0, 100 - (math.log(item.rank) / math.log(10)) * 15);
    }

    // 质量分 = 评分60% + 排名40%
    return scoreValue * 0.6 + rankValue * 0.4;
  }

  /// 计算时间衰减系数
  /// 使用指数衰减，让新番有更高权重
  static double _calculateTimeDecay(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 0.3;

    try {
      DateTime date = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      int daysDiff = now.difference(date).inDays;

      // 使用指数衰减函数
      // 半衰期设为180天（约6个月）
      // 这意味着6个月后，时间权重会降低到50%
      const double halfLife = 180.0;
      double decay = math.pow(0.5, daysDiff / halfLife).toDouble();

      // 限制最小值为0.1，避免老番完全消失
      return math.max(0.1, decay);
    } catch (e) {
      return 0.3;
    }
  }

  /// 计算时间新鲜度（用于展示）
  /// 返回0-100的分数
  static double calculateTimeFreshness(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 0;

    try {
      DateTime date = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      int daysDiff = now.difference(date).inDays;

      // 30天内: 100分
      if (daysDiff <= 30) return 100;
      // 90天内: 90分
      if (daysDiff <= 90) return 90;
      // 180天内: 80分
      if (daysDiff <= 180) return 80;
      // 365天内: 70分
      if (daysDiff <= 365) return 70;
      // 2年内: 50分
      if (daysDiff <= 730) return 50;
      // 3年内: 30分
      if (daysDiff <= 1095) return 30;
      // 5年内: 10分
      if (daysDiff <= 1825) return 10;
      // 5年以上: 5分
      return 5;
    } catch (e) {
      return 0;
    }
  }

  /// 获取热度排行榜
  static List<BangumiItem> getPopularityRanking(
    List<BangumiItem> items, {
    int limit = 10,
  }) {
    // 计算每个番剧的热度分数
    List<MapEntry<BangumiItem, double>> scoredItems = items.map((item) {
      double score = calculatePopularityScore(item);
      return MapEntry(item, score);
    }).toList();

    // 按分数降序排序
    scoredItems.sort((a, b) => b.value.compareTo(a.value));

    // 返回前N个
    return scoredItems.take(limit).map((e) => e.key).toList();
  }
}
