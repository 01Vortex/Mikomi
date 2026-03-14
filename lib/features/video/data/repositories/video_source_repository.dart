import 'package:mikomi/core/models/episode.dart';
import 'package:mikomi/features/video/data/datasources/video_source_datasource.dart';
import 'package:mikomi/features/video/data/services/video_plugin_service.dart';

class VideoSourceRepository {
  final VideoSourceDatasource _datasource = VideoSourceDatasourceImpl();
  final VideoPluginService _pluginService = VideoPluginService();

  /// 搜索动漫并获取第一个结果的剧集列表
  Future<List<Episode>> searchAndGetEpisodes(
    String keyword,
    String pluginName,
  ) async {
    try {
      final plugin = _pluginService.getPluginByName(pluginName);
      if (plugin == null) {
        print('插件 $pluginName 不存在');
        return [];
      }

      // 搜索动漫
      final searchResults = await _datasource.search(keyword, plugin);
      if (searchResults.isEmpty) {
        print('未找到搜索结果');
        return [];
      }

      // 获取第一个结果的剧集列表
      final firstResult = searchResults.first;
      final roads = await _datasource.getRoads(firstResult.url, plugin);

      if (roads.isEmpty) {
        print('未找到剧集列表');
        return [];
      }

      // 转换为Episode列表
      final firstRoad = roads.first;
      final episodes = <Episode>[];

      for (int i = 0; i < firstRoad.data.length; i++) {
        episodes.add(
          Episode.fromRoadData(
            index: i,
            identifier: i < firstRoad.identifier.length
                ? firstRoad.identifier[i]
                : '第${i + 1}集',
            url: firstRoad.data[i],
          ),
        );
      }

      return episodes;
    } catch (e) {
      print('搜索并获取剧集失败: $e');
      return [];
    }
  }

  /// 直接从URL获取剧集列表
  Future<List<Episode>> getEpisodesByUrl(String url, String pluginName) async {
    try {
      final plugin = _pluginService.getPluginByName(pluginName);
      if (plugin == null) {
        print('插件 $pluginName 不存在');
        return [];
      }

      final roads = await _datasource.getRoads(url, plugin);

      if (roads.isEmpty) {
        print('未找到剧集列表');
        return [];
      }

      // 转换为Episode列表
      final firstRoad = roads.first;
      final episodes = <Episode>[];

      for (int i = 0; i < firstRoad.data.length; i++) {
        episodes.add(
          Episode.fromRoadData(
            index: i,
            identifier: i < firstRoad.identifier.length
                ? firstRoad.identifier[i]
                : '第${i + 1}集',
            url: firstRoad.data[i],
          ),
        );
      }

      return episodes;
    } catch (e) {
      print('获取剧集失败: $e');
      return [];
    }
  }
}
