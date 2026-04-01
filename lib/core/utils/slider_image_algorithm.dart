import 'dart:math' as math;

import 'package:mikomi/core/models/bangumi_item.dart';

class SliderImageAlgorithm {
  /// 轮播图选择算法：
  /// - 基于综合评分选择高质量条目
  /// - 增加时效性与时间槽轮换因子，避免长期霸榜
  static List<BangumiItem> selectTopBanners(
    List<BangumiItem> items, {
    int count = 5,
  }) {
    if (items.isEmpty || count <= 0) {
      return [];
    }

    final uniqueMap = <int, BangumiItem>{};
    for (final item in items) {
      if (item.coverUrl.isEmpty) {
        continue;
      }
      uniqueMap[item.id] = item;
    }

    final uniqueItems = uniqueMap.values.toList();
    if (uniqueItems.isEmpty) {
      return [];
    }

    final slotSeed = _currentSlotSeed();

    final scored = uniqueItems.map((item) {
      final score = _calculateCompositeScore(item, slotSeed);
      return MapEntry(item, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(count).map((e) => e.key).toList();
  }

  static double _calculateCompositeScore(BangumiItem item, int slotSeed) {
    final ratingScore = (item.ratingScore.clamp(0, 10) / 10.0) * 100;

    double rankScore = 0;
    if (item.rank > 0) {
      rankScore = math.max(0, 100 - math.log(item.rank) / math.log(10) * 18);
    }

    final qualityScore = ratingScore * 0.72 + rankScore * 0.28;
    final freshness = _freshnessFactor(item.airDate);
    final rotationBonus = _rotationBonus(item.id, slotSeed);

    return qualityScore * (0.72 + freshness * 0.28) + rotationBonus;
  }

  static double _freshnessFactor(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return 0.2;
    }

    try {
      final airDate = DateTime.parse(dateStr);
      final days = DateTime.now().difference(airDate).inDays;
      const halfLife = 180.0;
      final decay = math.pow(0.5, days / halfLife).toDouble();
      return decay.clamp(0.18, 1.0);
    } catch (_) {
      return 0.2;
    }
  }

  static double _rotationBonus(int id, int slotSeed) {
    final mixed = (id * 1103515245 + slotSeed * 12345) & 0x7fffffff;
    final normalized = mixed / 0x7fffffff;
    return normalized * 6.0;
  }

  static int _currentSlotSeed() {
    final now = DateTime.now();
    final slot = now.hour >= 12 ? 1 : 0;
    return now.year * 10000 + now.month * 100 + now.day * 10 + slot;
  }
}
