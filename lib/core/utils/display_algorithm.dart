import 'dart:convert';
import 'dart:math';

import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisplayAlgorithm {
  static const int _featuredCount = 12;
  static const String _featuredIdsKey = 'home_featured_ids';
  static const String _featuredTimeKey = 'home_featured_time';

  /// 返回首页推荐展示页：
  /// - 第 1 页固定展示随机 12 条（每天 00:00 和 12:00 自动刷新）
  /// - 后续页展示剔除随机 12 条后的滚动列表
  static Future<List<BangumiItem>> buildRecommendPage({
    required List<BangumiItem> source,
    required int limit,
    required int offset,
  }) async {
    if (source.isEmpty || limit <= 0) {
      return [];
    }

    final featuredIds = await _getOrCreateFeaturedIds(source);
    final featuredItems = _orderedItemsByIds(source, featuredIds)
        .take(_featuredCount)
        .toList();

    if (offset == 0) {
      return featuredItems;
    }

    final featuredIdSet = featuredItems.map((e) => e.id).toSet();
    final normalItems =
        source.where((item) => !featuredIdSet.contains(item.id)).toList();

    final start = (offset - _featuredCount).clamp(0, normalItems.length);
    final end = (start + limit).clamp(0, normalItems.length);

    if (start >= end) {
      return [];
    }

    return normalItems.sublist(start, end);
  }

  static Future<List<int>> _getOrCreateFeaturedIds(List<BangumiItem> source) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final currentSlotStart = _getCurrentSlotStart(now);

    final savedTimeMs = prefs.getInt(_featuredTimeKey);
    final savedIdsRaw = prefs.getString(_featuredIdsKey);

    if (savedTimeMs != null && savedIdsRaw != null) {
      final savedTime = DateTime.fromMillisecondsSinceEpoch(savedTimeMs);
      final needRefresh = savedTime.isBefore(currentSlotStart);

      if (!needRefresh) {
        final savedIds = _decodeIds(savedIdsRaw);
        final sourceIdSet = source.map((e) => e.id).toSet();
        final validIds = savedIds.where(sourceIdSet.contains).toList();

        if (validIds.length >= _featuredCount) {
          return validIds.take(_featuredCount).toList();
        }
      }
    }

    final newIds = _createRandomIds(source, _featuredCount);

    await prefs.setString(_featuredIdsKey, jsonEncode(newIds));
    await prefs.setInt(_featuredTimeKey, now.millisecondsSinceEpoch);

    return newIds;
  }

  static DateTime _getCurrentSlotStart(DateTime now) {
    final slotHour = now.hour >= 12 ? 12 : 0;
    return DateTime(now.year, now.month, now.day, slotHour);
  }

  static List<int> _decodeIds(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<int>().toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static List<int> _createRandomIds(List<BangumiItem> source, int count) {
    final unique = <int, BangumiItem>{};
    for (final item in source) {
      unique[item.id] = item;
    }

    final items = unique.values.toList()..shuffle(Random());
    return items.take(count).map((e) => e.id).toList();
  }

  static List<BangumiItem> _orderedItemsByIds(
    List<BangumiItem> source,
    List<int> ids,
  ) {
    final map = {for (final item in source) item.id: item};
    return ids.map((id) => map[id]).whereType<BangumiItem>().toList();
  }
}
