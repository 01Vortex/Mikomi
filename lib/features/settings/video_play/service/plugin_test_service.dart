import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:mikomi/features/video/models/video_plugin.dart';
import 'package:mikomi/core/models/road.dart';
import 'package:mikomi/features/video/repository/video_episode_repository.dart';

/// 插件测试逻辑服务层（不依赖 Flutter UI）
class PluginTestService {
  final VideoPlugin plugin;
  late Dio _dio;
  CancelToken? cancelToken;

  PluginTestService(this.plugin) {
    _initDio();
  }

  void _initDio() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'referer': '${plugin.baseURL}/',
        'user-agent': plugin.userAgent.isNotEmpty
            ? plugin.userAgent
            : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept-Language': 'zh-CN,zh;q=0.9',
      },
    ));
  }

  void resetDio() => _initDio();

  Dio getDio() => _dio;

  void cancel(String reason) {
    cancelToken?.cancel(reason);
    cancelToken = null;
  }

  String buildSearchUrl(String keyword) {
    final s = plugin.searchURL.replaceAll('@keyword', keyword);
    return VideoEpisodeRepository.buildAbsoluteUrl(plugin.baseURL, s);
  }

  bool looksLikeCaptcha(String html) {
    final lower = html.toLowerCase();
    return VideoEpisodeRepository.looksLikeCaptchaPage(lower) ||
        lower.contains('smart-verify') ||
        lower.contains('verify-panel');
  }

  Future<String?> fetchHtml(String url) async {
    try {
      final response = await _dio.get(url, cancelToken: cancelToken);
      if (response.statusCode == 200) return response.data.toString();
      return null;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return null;
      rethrow;
    }
  }

  List<PluginSearchResult> parseSearchResults(String html) {
    try {
      final doc = html_parser.parse(html).documentElement;
      if (doc == null) return [];
      final results = <PluginSearchResult>[];
      for (var node in doc.queryXPath(plugin.searchList).nodes) {
        try {
          final nameNode = node.queryXPath(plugin.searchName).node;
          final resultNode = node.queryXPath(plugin.searchResult).node;
          if (nameNode == null || resultNode == null) continue;
          final name = nameNode.text?.trim() ?? '';
          final href = resultNode.attributes['href'] ?? '';
          if (name.isEmpty || href.isEmpty) continue;
          final fullUrl = VideoEpisodeRepository.buildAbsoluteUrl(
            plugin.baseURL,
            href,
          );
          results.add(PluginSearchResult(name: name, url: fullUrl));
        } catch (_) {}
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  List<Road> parseChapters(String html) {
    try {
      final doc = html_parser.parse(html).documentElement;
      if (doc == null) return [];
      final roadList = <Road>[];
      int count = 1;
      for (var roadNode in doc.queryXPath(plugin.chapterRoads).nodes) {
        final urls = <String>[], names = <String>[];
        for (var ch in roadNode.queryXPath(plugin.chapterResult).nodes) {
          final node = ch.node;
          final href = node.attributes['href'] ?? '';
          final name = node.text?.trim() ?? '';
          if (href.isEmpty || name.isEmpty) continue;
          final fullUrl = VideoEpisodeRepository.buildAbsoluteUrl(
            plugin.baseURL,
            href,
          );
          urls.add(fullUrl);
          names.add(name.replaceAll(RegExp(r'\s+'), ''));
        }
        if (urls.isNotEmpty) {
          roadList.add(Road(name: '播放列表$count', data: urls, identifier: names));
          count++;
        }
      }
      return roadList;
    } catch (_) {
      return [];
    }
  }
}

class PluginSearchResult {
  final String name;
  final String url;

  PluginSearchResult({required this.name, required this.url});
}
