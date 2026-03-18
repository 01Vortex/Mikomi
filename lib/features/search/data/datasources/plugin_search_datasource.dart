import 'package:flutter/foundation.dart';
import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/features/search/data/datasources/search_datasource.dart';
import 'package:mikomi/features/video/data/models/video_plugin.dart';
import 'package:mikomi/features/video/data/services/video_plugin_service.dart';

class PluginSearchDatasource implements SearchDatasource {
  final VideoPlugin plugin;
  final VideoPluginService _pluginService = VideoPluginService();

  PluginSearchDatasource(this.plugin);

  @override
  String get sourceName => plugin.name;

  @override
  int get priority => 2;

  @override
  Future<List<BangumiItem>> search(String keyword) async {
    try {
      // TODO: 实现插件搜索逻辑
      // 这里需要根据插件配置解析搜索结果
      // 暂时返回空列表
      debugPrint('[$sourceName] 插件搜索功能待实现');
      return [];
    } catch (e) {
      debugPrint('[$sourceName] 搜索失败: $e');
      rethrow;
    }
  }
}
