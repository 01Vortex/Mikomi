import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:mikomi/features/video/models/episode.dart';
import 'package:mikomi/core/models/road.dart';
import 'package:mikomi/features/video/models/video_plugin.dart';
import 'package:mikomi/features/video/services/video_plugin_service.dart';
import 'package:mikomi/features/video/services/video_source_provider.dart';

class SearchResult {
  final String name;
  final String url;

  SearchResult({required this.name, required this.url});
}

class VideoContentService {
  final VideoPluginService _pluginService = VideoPluginService();
  final IVideoSourceProvider _videoSourceProvider =
      WebViewVideoSourceProvider();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  /// 搜索动漫
  Future<List<SearchResult>> search(String keyword, VideoPlugin plugin) async {
    try {
      final searchUrl = plugin.searchURL.replaceAll('@keyword', keyword);

      String fullUrl;
      if (searchUrl.startsWith('http')) {
        fullUrl = searchUrl;
      } else if (searchUrl.startsWith('/')) {
        fullUrl = plugin.baseURL + searchUrl;
      } else {
        fullUrl = '${plugin.baseURL}/$searchUrl';
      }

      debugPrint('搜索URL: $fullUrl');

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

      if (response.statusCode == 200) {
        final htmlString = response.data.toString();

        if (_looksLikeCaptchaPage(htmlString) && plugin.antiCrawlerConfig.enabled) {
          throw CaptchaRequiredException(
            pluginName: plugin.name,
            pageUrl: fullUrl,
            captchaType: plugin.antiCrawlerConfig.captchaType,
            captchaImageXpath: plugin.antiCrawlerConfig.captchaImage,
            captchaInputXpath: plugin.antiCrawlerConfig.captchaInput,
            captchaButtonXpath: plugin.antiCrawlerConfig.captchaButton,
          );
        }

        final document = html_parser.parse(htmlString);
        final htmlElement = document.documentElement;
        if (htmlElement == null) return [];

        final results = <SearchResult>[];
        try {
          final searchNodes = htmlElement.queryXPath(plugin.searchList).nodes;
          for (var node in searchNodes) {
            try {
              final nameNode = node.queryXPath(plugin.searchName).node;
              final resultNode = node.queryXPath(plugin.searchResult).node;
              if (nameNode != null && resultNode != null) {
                final name = nameNode.text?.trim() ?? '';
                final href = resultNode.attributes['href'] ?? '';
                if (name.isNotEmpty && href.isNotEmpty) {
                  String fullResultUrl;
                  if (href.startsWith('http')) {
                    fullResultUrl = href;
                  } else if (href.startsWith('/')) {
                    fullResultUrl = plugin.baseURL + href;
                  } else {
                    fullResultUrl = '${plugin.baseURL}/$href';
                  }
                  results.add(SearchResult(name: name, url: fullResultUrl));
                }
              }
            } catch (e) {
              debugPrint('解析搜索结果项失败: $e');
            }
          }
        } catch (e) {
          debugPrint('XPath查询失败: $e');
        }

        return results;
      }
      return [];
    } on CaptchaRequiredException {
      rethrow;
    } catch (e) {
      debugPrint('搜索失败: $e');
      return [];
    }
  }

  /// 搜索动漫并获取第一个匹配结果的剧集列表
  Future<List<Episode>> searchAndGetEpisodes(
    String keyword,
    String pluginName,
  ) async {
    try {
      final plugin = _pluginService.getPluginByName(pluginName);
      if (plugin == null) return [];

      final searchResults = await search(keyword, plugin);
      if (searchResults.isEmpty) return [];

      final matchedResult = _selectBestSearchResult(keyword, searchResults);
      if (matchedResult == null) return [];

      final roads = await getRoads(matchedResult.url, plugin);
      if (roads.isEmpty) return [];

      return _roadToEpisodes(roads.first);
    } catch (e, stackTrace) {
      debugPrint('搜索并获取剧集失败: $e');
      debugPrint('堆栈: $stackTrace');
      return [];
    }
  }

  /// 直接从URL获取剧集列表
  Future<List<Episode>> getEpisodesByUrl(
      String url, String pluginName) async {
    try {
      final plugin = _pluginService.getPluginByName(pluginName);
      if (plugin == null) return [];
      final roads = await getRoads(url, plugin);
      if (roads.isEmpty) return [];
      return _roadToEpisodes(roads.first);
    } catch (e) {
      debugPrint('获取剧集失败: $e');
      return [];
    }
  }

  /// 获取剧集播放列表
  Future<List<Road>> getRoads(String url, VideoPlugin plugin) async {
    try {
      String fullUrl;
      if (url.startsWith('http')) {
        fullUrl = url;
        if (fullUrl.startsWith('http://') &&
            plugin.baseURL.startsWith('https://')) {
          fullUrl = fullUrl.replaceFirst('http://', 'https://');
        }
      } else if (url.startsWith('/')) {
        fullUrl = plugin.baseURL + url;
      } else {
        fullUrl = '${plugin.baseURL}/$url';
      }

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

      if (response.statusCode == 200) {
        final htmlString = response.data.toString();

        if (_looksLikeCaptchaPage(htmlString) && plugin.antiCrawlerConfig.enabled) {
          throw CaptchaRequiredException(
            pluginName: plugin.name,
            pageUrl: fullUrl,
            captchaType: plugin.antiCrawlerConfig.captchaType,
            captchaImageXpath: plugin.antiCrawlerConfig.captchaImage,
            captchaInputXpath: plugin.antiCrawlerConfig.captchaInput,
            captchaButtonXpath: plugin.antiCrawlerConfig.captchaButton,
          );
        }

        final document = html_parser.parse(htmlString);
        final htmlElement = document.documentElement;
        if (htmlElement == null) return [];

        final roadList = <Road>[];
        try {
          final roadNodes = htmlElement.queryXPath(plugin.chapterRoads).nodes;
          int count = 1;
          for (var roadNode in roadNodes) {
            try {
              final chapterNodes =
                  roadNode.queryXPath(plugin.chapterResult).nodes;
              final chapterUrls = <String>[];
              final chapterNames = <String>[];
              for (var chapterNode in chapterNodes) {
                final node = chapterNode.node;
                final href = node.attributes['href'] ?? '';
                final name = node.text?.trim() ?? '';
                if (href.isNotEmpty && name.isNotEmpty) {
                  String fullChapterUrl;
                  if (href.startsWith('http')) {
                    fullChapterUrl = href;
                  } else if (href.startsWith('/')) {
                    fullChapterUrl = plugin.baseURL + href;
                  } else {
                    fullChapterUrl = '${plugin.baseURL}/$href';
                  }
                  chapterUrls.add(fullChapterUrl);
                  chapterNames.add(name.replaceAll(RegExp(r'\s+'), ''));
                }
              }
              if (chapterUrls.isNotEmpty && chapterNames.isNotEmpty) {
                roadList.add(Road(
                  name: '播放列表$count',
                  data: chapterUrls,
                  identifier: chapterNames,
                ));
                count++;
              }
            } catch (e) {
              debugPrint('解析播放列表失败: $e');
            }
          }
        } catch (e) {
          debugPrint('XPath查询失败: $e');
        }

        return roadList;
      }
      return [];
    } on CaptchaRequiredException {
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('获取剧集列表失败: $e');
      debugPrint('堆栈: $stackTrace');
      return [];
    }
  }

  void cancelVideoParsing() {
    _videoSourceProvider.cancel();
  }

  /// 解析视频播放地址
  Future<String> parseVideoUrl(String pageUrl, String pluginName) async {
    final plugin = _pluginService.getPluginByName(pluginName);
    if (plugin == null) throw Exception('插件不存在: $pluginName');

    if (!plugin.useWebview) return pageUrl;

    final source = await _videoSourceProvider.resolve(
      pageUrl,
      useLegacyParser: plugin.useLegacyParser,
      timeout: const Duration(seconds: 45),
    );
    return source.url;
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

    if (candidates.isNotEmpty) {
      candidates.sort((a, b) {
        final aDiff =
            (_normalizeTitle(a.name).length - normalizedKeyword.length).abs();
        final bDiff =
            (_normalizeTitle(b.name).length - normalizedKeyword.length).abs();
        return aDiff.compareTo(bDiff);
      });
      return candidates.first;
    }
    return null;
  }

  List<Episode> _roadToEpisodes(Road road) {
    final episodes = <Episode>[];
    for (int i = 0; i < road.data.length; i++) {
      episodes.add(Episode.fromRoadData(
        index: i,
        identifier:
            i < road.identifier.length ? road.identifier[i] : '第${i + 1}集',
        url: road.data[i],
      ));
    }
    episodes.sort((a, b) => a.number.compareTo(b.number));
    return episodes;
  }
}
