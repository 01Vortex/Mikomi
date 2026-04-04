import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:mikomi/core/models/road.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/models/video_plugin.dart';
import 'package:mikomi/features/video/services/video_exception.dart';
import 'package:mikomi/features/video/services/video_plugin_service.dart';
import 'package:mikomi/features/video/services/video_stream_service.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

class SearchResult {
  final String name;
  final String url;

  SearchResult({required this.name, required this.url});
}

class VideoService {
  final VideoPluginService _pluginService = VideoPluginService();
  final VideoStreamService _videoStreamService = WebViewVideoStreamService();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  Future<List<SearchResult>> searchGateway(
    String keyword,
    VideoPlugin plugin,
  ) async {
    try {
      final searchUrl = plugin.searchURL.replaceAll('@keyword', keyword);
      final fullUrl = _buildAbsoluteUrl(plugin.baseURL, searchUrl);

      final response = await _dio.get(
        fullUrl,
        options: Options(
          headers: {
            'referer': '${plugin.baseURL}/',
            'user-agent': plugin.userAgent.isNotEmpty
                ? plugin.userAgent
                : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Connection': 'keep-alive',
          },
        ),
      );

      if (response.statusCode != 200) return [];
      final htmlString = response.data.toString();
      _throwIfCaptchaRequired(htmlString, plugin, fullUrl);

      final document = html_parser.parse(htmlString);
      final htmlElement = document.documentElement;
      if (htmlElement == null) return [];

      final results = <SearchResult>[];
      final nodes = htmlElement.queryXPath(plugin.searchList).nodes;
      for (final node in nodes) {
        final nameNode = node.queryXPath(plugin.searchName).node;
        final resultNode = node.queryXPath(plugin.searchResult).node;
        if (nameNode == null || resultNode == null) continue;

        final name = nameNode.text?.trim() ?? '';
        final href = resultNode.attributes['href'] ?? '';
        if (name.isEmpty || href.isEmpty) continue;

        results.add(
          SearchResult(
            name: name,
            url: _buildAbsoluteUrl(plugin.baseURL, href),
          ),
        );
      }

      return results;
    } on VideoCaptchaRequiredException {
      rethrow;
    } catch (e) {
      debugPrint('搜索失败: $e');
      return [];
    }
  }

  Future<List<Episode>> episodeGateway(
    String keyword,
    String pluginName,
  ) async {
    try {
      final plugin = _pluginService.getPluginByName(pluginName);
      if (plugin == null) return [];

      final searchResults = await searchGateway(keyword, plugin);
      if (searchResults.isEmpty) return [];

      final matchedResult = _selectBestSearchResult(keyword, searchResults);
      if (matchedResult == null) return [];

      final roads = await _loadRoads(matchedResult.url, plugin);
      if (roads.isEmpty) return [];

      return _roadToEpisodes(roads.first);
    } on VideoCaptchaRequiredException {
      rethrow;
    } catch (e) {
      debugPrint('获取剧集失败: $e');
      return [];
    }
  }

  Future<String> parseGateway(String pageUrl, String pluginName) async {
    final plugin = _pluginService.getPluginByName(pluginName);
    if (plugin == null) {
      throw const VideoException(VideoExceptionCode.pluginNotFound);
    }

    if (!plugin.useWebview) return pageUrl;

    final source = await _videoStreamService.resolveFromPage(
      pageUrl,
      useAlternativeParser: plugin.useLegacyParser,
      timeout: const Duration(seconds: 45),
      options: VideoStreamResolveOptions(
        captchaType: plugin.antiCrawlerConfig.captchaType,
        captchaImageXpath: plugin.antiCrawlerConfig.captchaImage,
        captchaInputXpath: plugin.antiCrawlerConfig.captchaInput,
        captchaButtonXpath: plugin.antiCrawlerConfig.captchaButton,
      ),
    );
    return source.url;
  }

  void cancelVideoParsing() {
    _videoStreamService.cancel();
  }

  Future<List<Road>> _loadRoads(String url, VideoPlugin plugin) async {
    try {
      final fullUrl = _buildAbsoluteUrl(plugin.baseURL, url);
      final response = await _dio.get(
        fullUrl,
        options: Options(
          headers: {
            'referer': '${plugin.baseURL}/',
            'user-agent': plugin.userAgent.isNotEmpty
                ? plugin.userAgent
                : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
            'Connection': 'keep-alive',
          },
        ),
      );

      if (response.statusCode != 200) return [];

      final htmlString = response.data.toString();
      _throwIfCaptchaRequired(htmlString, plugin, fullUrl);

      final document = html_parser.parse(htmlString);
      final htmlElement = document.documentElement;
      if (htmlElement == null) return [];

      final roadList = <Road>[];
      final roadNodes = htmlElement.queryXPath(plugin.chapterRoads).nodes;
      var count = 1;

      for (final roadNode in roadNodes) {
        final chapterNodes = roadNode.queryXPath(plugin.chapterResult).nodes;
        final chapterUrls = <String>[];
        final chapterNames = <String>[];

        for (final chapterNode in chapterNodes) {
          final node = chapterNode.node;
          final href = node.attributes['href'] ?? '';
          final name = node.text?.trim() ?? '';
          if (href.isEmpty || name.isEmpty) continue;

          chapterUrls.add(_buildAbsoluteUrl(plugin.baseURL, href));
          chapterNames.add(name.replaceAll(RegExp(r'\s+'), ''));
        }

        if (chapterUrls.isNotEmpty && chapterNames.isNotEmpty) {
          roadList.add(
            Road(
              name: '播放列表$count',
              data: chapterUrls,
              identifier: chapterNames,
            ),
          );
          count++;
        }
      }

      return roadList;
    } on VideoCaptchaRequiredException {
      rethrow;
    } catch (e) {
      debugPrint('获取剧集列表失败: $e');
      return [];
    }
  }

  void _throwIfCaptchaRequired(
    String html,
    VideoPlugin plugin,
    String pageUrl,
  ) {
    if (!_looksLikeCaptchaPage(html) || !plugin.antiCrawlerConfig.enabled) {
      return;
    }

    throw VideoCaptchaRequiredException(
      pluginName: plugin.name,
      pageUrl: pageUrl,
      captchaType: plugin.antiCrawlerConfig.captchaType,
      captchaImageXpath: plugin.antiCrawlerConfig.captchaImage,
      captchaInputXpath: plugin.antiCrawlerConfig.captchaInput,
      captchaButtonXpath: plugin.antiCrawlerConfig.captchaButton,
    );
  }

  String _buildAbsoluteUrl(String baseUrl, String path) {
    if (path.startsWith('http')) {
      if (path.startsWith('http://') && baseUrl.startsWith('https://')) {
        return path.replaceFirst('http://', 'https://');
      }
      return path;
    }
    if (path.startsWith('/')) return baseUrl + path;
    return '$baseUrl/$path';
  }

  bool _looksLikeCaptchaPage(String html) {
    final lower = html.toLowerCase();
    return lower.contains('captcha') ||
        lower.contains('验证码') ||
        lower.contains('verify') ||
        lower.contains('人机验证') ||
        lower.contains('geetest') ||
        lower.contains('turnstile');
  }

  String _normalizeTitle(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-z0-9\u4e00-\u9fa5]'), '');
  }

  SearchResult? _selectBestSearchResult(
    String keyword,
    List<SearchResult> results,
  ) {
    final normalizedKeyword = _normalizeTitle(keyword);

    for (final result in results) {
      if (_normalizeTitle(result.name) == normalizedKeyword) return result;
    }

    final keywordPrefixRegex = RegExp(
      '^${RegExp.escape(normalizedKeyword)}(?!\\d)',
      caseSensitive: false,
    );

    final candidates = results
        .where((r) => keywordPrefixRegex.hasMatch(_normalizeTitle(r.name)))
        .toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final aDiff = (_normalizeTitle(a.name).length - normalizedKeyword.length)
          .abs();
      final bDiff = (_normalizeTitle(b.name).length - normalizedKeyword.length)
          .abs();
      return aDiff.compareTo(bDiff);
    });

    return candidates.first;
  }

  List<Episode> _roadToEpisodes(Road road) {
    final episodes = <Episode>[];
    for (var i = 0; i < road.data.length; i++) {
      episodes.add(
        Episode.fromRoadData(
          index: i,
          identifier: i < road.identifier.length
              ? road.identifier[i]
              : '第${i + 1}集',
          url: road.data[i],
        ),
      );
    }
    episodes.sort((a, b) => a.number.compareTo(b.number));
    return episodes;
  }
}
