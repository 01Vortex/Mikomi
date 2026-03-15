import 'package:mikomi/core/models/episode.dart';
import 'package:mikomi/features/video/data/datasources/video_source_datasource.dart';
import 'package:mikomi/features/video/data/services/video_plugin_service.dart';
import 'package:mikomi/features/video/data/services/webview_video_parser.dart';
import 'package:flutter/foundation.dart';

class VideoSourceRepository {
  final VideoSourceDatasource _datasource = VideoSourceDatasourceImpl();
  final VideoPluginService _pluginService = VideoPluginService();
  final WebViewVideoParser _webViewParser = WebViewVideoParser();

  /// 搜索动漫并获取第一个结果的剧集列表（用于检测资源可用性）
  Future<List<Episode>> searchAndGetEpisodes(
    String keyword,
    String pluginName,
  ) async {
    try {
      final plugin = _pluginService.getPluginByName(pluginName);
      if (plugin == null) {
        debugPrint('插件 $pluginName 不存在');
        return [];
      }

      // 搜索动漫
      debugPrint('开始搜索: $keyword');
      final searchResults = await _datasource.search(keyword, plugin);
      if (searchResults.isEmpty) {
        debugPrint('未找到搜索结果');
        return [];
      }

      debugPrint('找到 ${searchResults.length} 个搜索结果');

      // 获取第一个结果的剧集列表
      final firstResult = searchResults.first;
      debugPrint('获取剧集列表: ${firstResult.name}');
      final roads = await _datasource.getRoads(firstResult.url, plugin);

      if (roads.isEmpty) {
        debugPrint('未找到剧集列表');
        return [];
      }

      debugPrint('成功获取 ${roads.length} 个播放列表');

      // 转换为Episode列表（不解析视频地址，只返回原始URL）
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

      debugPrint('转换为 ${episodes.length} 集');
      return episodes;
    } catch (e) {
      debugPrint('搜索并获取剧集失败: $e');
      return [];
    }
  }

  /// 直接从URL获取剧集列表
  Future<List<Episode>> getEpisodesByUrl(String url, String pluginName) async {
    try {
      final plugin = _pluginService.getPluginByName(pluginName);
      if (plugin == null) {
        debugPrint('插件 $pluginName 不存在');
        return [];
      }

      final roads = await _datasource.getRoads(url, plugin);

      if (roads.isEmpty) {
        debugPrint('未找到剧集列表');
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
      debugPrint('获取剧集失败: $e');
      return [];
    }
  }

  /// 解析视频播放地址（用于实际播放）
  Future<String> parseVideoUrl(String pageUrl, String pluginName) async {
    try {
      final plugin = _pluginService.getPluginByName(pluginName);
      if (plugin == null) {
        debugPrint('插件 $pluginName 不存在');
        return pageUrl;
      }

      // 如果插件需要使用WebView，使用 WebView 解析
      if (plugin.useWebview) {
        debugPrint('========== 开始 WebView 解析 ==========');
        debugPrint('页面URL: $pageUrl');
        debugPrint('插件: $pluginName');
        debugPrint('使用Legacy模式: ${plugin.useLegacyParser}');

        // 使用插件配置的解析模式,支持多层解析
        final parsedUrl = await _webViewParser.parseVideoUrl(
          pageUrl,
          useLegacyParser: plugin.useLegacyParser,
          timeout: const Duration(seconds: 45),
          maxDepth: 3,
        );

        if (parsedUrl != null && parsedUrl.isNotEmpty) {
          debugPrint('========== 最终解析结果 ==========');
          debugPrint('视频流URL: $parsedUrl');
          debugPrint('==================================');
          return parsedUrl;
        } else {
          debugPrint('WebView 解析失败，使用原始URL');
          debugPrint('==================================');
          return pageUrl;
        }
      }

      // 不需要解析，直接返回原始URL
      return pageUrl;
    } catch (e) {
      debugPrint('解析视频地址失败: $e');
      return pageUrl;
    }
  }
}
