import 'dart:math' as math;
import 'package:mikomi/core/models/bangumi_item.dart';

class PopularityAlgorithm {
  /// 计算番剧热度分数
  /// 综合考虑:
  /// - 评分 (40%)
  /// - 排名 (30%)
  /// - 时间新鲜度 (30%)
  static double calculatePopularityScore(BangumiItem item) {
    double scoreWeight = 0.4;
    double rankWeight = 0.3;
    double timeWeight = 0.3;

    // 评分分数 (0-10分 -> 0-100分)
    double scoreValue = (item.ratingScore / 10.0) * 100;

    // 排名分数 (排名越小分数越高)
    double rankValue = 0;
    if (item.rank > 0) {
      rankValue = math.max(0, 100 - (item.rank / 10.0));
    }

    // 时间新鲜度分数
    double timeValue = _calculateTimeFreshness(item.airDate);

    // 综合分数
    double totalScore =
        (scoreValue * scoreWeight) +
        (rankValue * rankWeight) +
        (timeValue * timeWeight);

    return totalScore;
  }

  /// 计算时间新鲜度
  /// 最近1年内的番剧得分最高
  static double _calculateTimeFreshness(String? dateStr) {
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
