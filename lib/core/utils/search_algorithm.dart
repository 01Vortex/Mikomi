import 'package:mikomi/core/models/bangumi_item.dart';

class SearchAlgorithm {
  /// 精准搜索排序
  /// 匹配优先级:
  /// 1. 完全匹配 (100分)
  /// 2. 开头匹配 (80分)
  /// 3. 包含匹配 (60分)
  /// 4. 模糊匹配 (40分)
  static List<BangumiItem> sortByRelevance(
    List<BangumiItem> items,
    String keyword,
  ) {
    if (keyword.trim().isEmpty) return items;

    final lowerKeyword = keyword.toLowerCase().trim();

    // 计算每个番剧的相关度分数
    List<MapEntry<BangumiItem, double>> scoredItems = items.map((item) {
      double score = _calculateRelevanceScore(item, lowerKeyword);
      return MapEntry(item, score);
    }).toList();

    // 按分数降序排序
    scoredItems.sort((a, b) => b.value.compareTo(a.value));

    return scoredItems.map((e) => e.key).toList();
  }

  /// 计算相关度分数
  static double _calculateRelevanceScore(BangumiItem item, String keyword) {
    final nameCn = item.nameCn.toLowerCase();
    final name = item.name.toLowerCase();

    double maxScore = 0;

    // 检查中文名
    maxScore = _max(maxScore, _matchScore(nameCn, keyword));

    // 检查原名
    maxScore = _max(maxScore, _matchScore(name, keyword));

    // 加上评分和排名的权重
    double ratingBonus = (item.ratingScore / 10.0) * 10; // 最多10分
    double rankBonus = 0;
    if (item.rank > 0 && item.rank <= 1000) {
      rankBonus = (1000 - item.rank) / 100; // 最多10分
    }

    return maxScore + ratingBonus + rankBonus;
  }

  /// 匹配分数计算
  static double _matchScore(String text, String keyword) {
    if (text.isEmpty) return 0;

    // 完全匹配
    if (text == keyword) return 100;

    // 开头匹配
    if (text.startsWith(keyword)) return 80;

    // 包含匹配
    if (text.contains(keyword)) {
      // 关键词在文本中的位置越靠前,分数越高
      int index = text.indexOf(keyword);
      double positionScore = 60 - (index / text.length * 20);
      return positionScore;
    }

    // 模糊匹配 (检查关键词的每个字符是否按顺序出现)
    if (_fuzzyMatch(text, keyword)) {
      return 40;
    }

    return 0;
  }

  /// 模糊匹配
  /// 检查keyword的每个字符是否按顺序出现在text中
  static bool _fuzzyMatch(String text, String keyword) {
    int textIndex = 0;
    int keywordIndex = 0;

    while (textIndex < text.length && keywordIndex < keyword.length) {
      if (text[textIndex] == keyword[keywordIndex]) {
        keywordIndex++;
      }
      textIndex++;
    }

    return keywordIndex == keyword.length;
  }

  /// 过滤低相关度结果
  /// 只保留分数大于阈值的结果
  static List<BangumiItem> filterByRelevance(
    List<BangumiItem> items,
    String keyword, {
    double minScore = 30,
  }) {
    if (keyword.trim().isEmpty) return items;

    final lowerKeyword = keyword.toLowerCase().trim();

    return items.where((item) {
      double score = _calculateRelevanceScore(item, lowerKeyword);
      return score >= minScore;
    }).toList();
  }

  static double _max(double a, double b) => a > b ? a : b;
}
