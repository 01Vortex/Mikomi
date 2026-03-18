import 'package:flutter/foundation.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/features/search/data/datasources/search_datasource.dart';
import 'package:mikomi/features/search/data/datasources/bangumi_search_datasource.dart';
import 'package:mikomi/features/search/data/models/search_result.dart';

class MultiSourceSearchService {
  static final MultiSourceSearchService _instance =
      MultiSourceSearchService._internal();
  factory MultiSourceSearchService() => _instance;
  MultiSourceSearchService._internal();

  final List<SearchDatasource> _datasources = [];
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    _datasources.add(BangumiSearchDatasource());

    _datasources.sort((a, b) => a.priority.compareTo(b.priority));

    _initialized = true;
    debugPrint('搜索数据源初始化完成，共 ${_datasources.length} 个');
  }

  Future<List<BangumiItem>> search(String keyword) async {
    if (!_initialized) {
      await initialize();
    }

    if (keyword.trim().isEmpty) {
      return [];
    }

    for (final datasource in _datasources) {
      try {
        debugPrint('[${datasource.sourceName}] 开始搜索: $keyword');
        final results = await datasource.search(keyword);

        if (results.isNotEmpty) {
          debugPrint(
            '[${datasource.sourceName}] 搜索成功，找到 ${results.length} 条结果',
          );
          return results;
        }

        debugPrint('[${datasource.sourceName}] 未找到结果，尝试下一个数据源');
      } catch (e) {
        debugPrint('[${datasource.sourceName}] 搜索失败: $e，尝试下一个数据源');
        continue;
      }
    }

    debugPrint('所有数据源搜索失败');
    return [];
  }

  Future<Map<String, SearchResult>> searchAll(String keyword) async {
    if (!_initialized) {
      await initialize();
    }

    if (keyword.trim().isEmpty) {
      return {};
    }

    final results = <String, SearchResult>{};

    await Future.wait(
      _datasources.map((datasource) async {
        try {
          debugPrint('[${datasource.sourceName}] 开始并发搜索: $keyword');
          final items = await datasource.search(keyword);
          results[datasource.sourceName] = SearchResult.success(
            datasource.sourceName,
            items,
          );
        } catch (e) {
          debugPrint('[${datasource.sourceName}] 搜索失败: $e');
          results[datasource.sourceName] = SearchResult.failure(
            datasource.sourceName,
            e.toString(),
          );
        }
      }),
    );

    return results;
  }

  List<BangumiItem> mergeResults(Map<String, SearchResult> results) {
    final allItems = <BangumiItem>[];
    final seenIds = <int>{};

    final sortedSources = results.entries.toList()
      ..sort((a, b) {
        final sourceA = _datasources.firstWhere(
          (ds) => ds.sourceName == a.key,
          orElse: () => _datasources.first,
        );
        final sourceB = _datasources.firstWhere(
          (ds) => ds.sourceName == b.key,
          orElse: () => _datasources.first,
        );
        return sourceA.priority.compareTo(sourceB.priority);
      });

    for (final entry in sortedSources) {
      if (!entry.value.isSuccess) continue;

      for (final item in entry.value.items) {
        if (!seenIds.contains(item.id)) {
          seenIds.add(item.id);
          allItems.add(item);
        }
      }
    }

    return allItems;
  }
}
