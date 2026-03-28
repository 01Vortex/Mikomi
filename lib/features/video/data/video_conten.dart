import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:mikomi/core/models/road.dart';
import 'package:mikomi/core/models/video_plugin.dart';
import 'package:mikomi/features/video/services/video_plugin_service.dart';
import 'package:mikomi/features/video/services/parser/video_source_provider.dart';

class SearchResult {
  final String name;
  final String url;

  SearchResult({required this.name, required this.url});
}

class VideoConten {
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

      // 构建完整URL
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

      debugPrint('响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final htmlString = response.data.toString();
        debugPrint('HTML长度: ${htmlString.length}');

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

        if (htmlElement == null) {
          debugPrint('HTML解析失败：documentElement为null');
          return [];
        }

        final results = <SearchResult>[];

        try {
          debugPrint('使用XPath: ${plugin.searchList}');
          final searchNodes = htmlElement.queryXPath(plugin.searchList).nodes;
          debugPrint('找到 ${searchNodes.length} 个搜索结果节点');

          if (searchNodes.isEmpty) {
            debugPrint('警告: 未找到搜索结果节点,可能XPath不正确');

            // 查找videos容器的子元素
            try {
              final videosNodes = htmlElement
                  .queryXPath("//div[@class='videos']")
                  .nodes;
              if (videosNodes.isNotEmpty) {
                debugPrint('找到videos容器');
                final videosNode = videosNodes.first.node;
                final children = videosNode.children;
                debugPrint('videos有 ${children.length} 个子元素');
                for (
                  int i = 0;
                  i < (children.length > 5 ? 5 : children.length);
                  i++
                ) {
                  final child = children[i];
                  final childClass = child.attributes['class'] ?? '无class';
                  final childTag = child.localName ?? '无标签';
                  debugPrint('  子元素$i: <$childTag> class="$childClass"');

                  // 输出孙元素
                  if (child.children.isNotEmpty) {
                    debugPrint('    有 ${child.children.length} 个孙元素');
                    for (
                      int j = 0;
                      j <
                          (child.children.length > 3
                              ? 3
                              : child.children.length);
                      j++
                    ) {
                      final grandChild = child.children[j];
                      final gcClass =
                          grandChild.attributes['class'] ?? '无class';
                      final gcTag = grandChild.localName ?? '无标签';
                      final gcText = grandChild.text.trim();
                      final gcTextPreview = gcText.length > 30
                          ? gcText.substring(0, 30)
                          : gcText;
                      debugPrint(
                        '      孙元素$j: <$gcTag> class="$gcClass", text="$gcTextPreview"',
                      );
                    }
                  }
                }
              }
            } catch (e) {
              debugPrint('查询videos容器失败: $e');
            }
          }

          for (var node in searchNodes) {
            try {
              final nameNode = node.queryXPath(plugin.searchName).node;
              final resultNode = node.queryXPath(plugin.searchResult).node;

              if (nameNode != null && resultNode != null) {
                final name = nameNode.text?.trim() ?? '';
                final href = resultNode.attributes['href'] ?? '';

                debugPrint('找到结果: $name -> $href');

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

        debugPrint('共找到 ${results.length} 个有效结果');
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

  /// 搜索动漫并获取第一个结果的剧集列表（用于检测资源可用性）
  Future<List<Episode>> searchAndGetEpisodes(
    String keyword,
    String pluginName,
  ) async {
    try {
      final plugin = _pluginService.getPluginByName(pluginName);
      if (plugin == null) {
        debugPrint('[$pluginName] 插件不存在');
        return [];
      }

      // 搜索动漫
      debugPrint('[$pluginName] 开始搜索: $keyword');
      final searchResults = await search(keyword, plugin);

      if (searchResults.isEmpty) {
        debugPrint('[$pluginName] 未找到搜索结果');
        return [];
      }

      debugPrint('[$pluginName] 找到 ${searchResults.length} 个搜索结果');

      final matchedResult = _selectBestSearchResult(keyword, searchResults);
      if (matchedResult == null) {
        debugPrint('[$pluginName] 未找到与 "$keyword" 完全匹配的结果，终止解析');
        return [];
      }

      // 获取完全匹配结果的剧集列表
      final firstResult = matchedResult;
      debugPrint('[$pluginName] 获取剧集列表: ${firstResult.name}');
      debugPrint('[$pluginName] 剧集URL: ${firstResult.url}');

      final roads = await getRoads(firstResult.url, plugin);

      if (roads.isEmpty) {
        debugPrint('[$pluginName] 未找到剧集列表');
        return [];
      }

      debugPrint('[$pluginName] 成功获取 ${roads.length} 个播放列表');

      final firstRoad = roads.first;
      debugPrint('[$pluginName] 第一个播放列表有 ${firstRoad.data.length} 集');

      final episodes = _roadToEpisodes(firstRoad);
      debugPrint('[$pluginName] 转换为 ${episodes.length} 集');
      return episodes;
    } catch (e, stackTrace) {
      debugPrint('[$pluginName] 搜索并获取剧集失败: $e');
      debugPrint('[$pluginName] 堆栈: $stackTrace');
      return [];
    }
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

    // 第一优先：完全匹配
    for (final result in results) {
      if (_normalizeTitle(result.name) == normalizedKeyword) {
        debugPrint('搜索完全匹配命中: ${result.name}');
        return result;
      }
    }

    // 第二优先：结果名字以 keyword 开头且后面不直接跟数字
    // 收集所有候选，选名字长度与 keyword 最接近的，避免误选更短的同名前缀
    final keywordPrefixRegex = RegExp(
      '^${RegExp.escape(normalizedKeyword)}(?!\\d)',
      caseSensitive: false,
    );

    final candidates = <SearchResult>[];
    for (final result in results) {
      final normalizedName = _normalizeTitle(result.name);
      if (keywordPrefixRegex.hasMatch(normalizedName)) {
        candidates.add(result);
      }
    }

    if (candidates.isNotEmpty) {
      // 选长度差最小的，即名字与 keyword 最接近的结果
      candidates.sort((a, b) {
        final aDiff =
            (_normalizeTitle(a.name).length - normalizedKeyword.length).abs();
        final bDiff =
            (_normalizeTitle(b.name).length - normalizedKeyword.length).abs();
        return aDiff.compareTo(bDiff);
      });
      debugPrint('搜索前缀匹配命中: ${candidates.first.name}');
      return candidates.first;
    }

    return null;
  }

  /// 直接从URL获取剧集列表
  Future<List<Episode>> getEpisodesByUrl(String url, String pluginName) async {
    try {
      final plugin = _pluginService.getPluginByName(pluginName);
      if (plugin == null) {
        debugPrint('插件 $pluginName 不存在');
        return [];
      }

      final roads = await getRoads(url, plugin);

      if (roads.isEmpty) {
        debugPrint('未找到剧集列表');
        return [];
      }

      return _roadToEpisodes(roads.first);
    } catch (e) {
      debugPrint('获取剧集失败: $e');
      return [];
    }
  }

  /// 将 Road 转换为按集数正序排列的 Episode 列表
  List<Episode> _roadToEpisodes(Road road) {
    final episodes = <Episode>[];
    for (int i = 0; i < road.data.length; i++) {
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
    // 按集数正序排列，消除插件网站返回顺序的影响
    episodes.sort((a, b) => a.number.compareTo(b.number));
    return episodes;
  }

  /// 获取剧集列表
  Future<List<Road>> getRoads(String url, VideoPlugin plugin) async {
    try {
      // 构建完整URL
      String fullUrl;
      if (url.startsWith('http')) {
        fullUrl = url;
        // 确保使用HTTPS
        if (fullUrl.startsWith('http://') &&
            plugin.baseURL.startsWith('https://')) {
          fullUrl = fullUrl.replaceFirst('http://', 'https://');
          debugPrint('URL协议转换为HTTPS: $fullUrl');
        }
      } else if (url.startsWith('/')) {
        fullUrl = plugin.baseURL + url;
      } else {
        fullUrl = '${plugin.baseURL}/$url';
      }

      debugPrint('获取剧集URL: $fullUrl');

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

      debugPrint('响应状态码: ${response.statusCode}');

      if (response.statusCode == 200) {
        final htmlString = response.data.toString();
        debugPrint('HTML长度: ${htmlString.length}');

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

        if (htmlElement == null) {
          debugPrint('HTML解析失败：documentElement为null');
          return [];
        }

        final roadList = <Road>[];

        try {
          debugPrint('使用XPath: ${plugin.chapterRoads}');
          final roadNodes = htmlElement.queryXPath(plugin.chapterRoads).nodes;
          debugPrint('找到 ${roadNodes.length} 个播放列表节点');

          if (roadNodes.isEmpty) {
            debugPrint('警告: 未找到播放列表节点,可能XPath不正确');
            debugPrint(
              'HTML前500字符: ${htmlString.substring(0, htmlString.length > 500 ? 500 : htmlString.length)}',
            );
          }

          int count = 1;
          for (var roadNode in roadNodes) {
            try {
              final chapterNodes = roadNode
                  .queryXPath(plugin.chapterResult)
                  .nodes;

              debugPrint('播放列表$count 找到 ${chapterNodes.length} 集');

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
                debugPrint('播放列表$count: ${chapterNames.length} 集');
                roadList.add(
                  Road(
                    name: '播放列表$count',
                    data: chapterUrls,
                    identifier: chapterNames,
                  ),
                );
                count++;
              }
            } catch (e) {
              debugPrint('解析播放列表失败: $e');
            }
          }
        } catch (e) {
          debugPrint('XPath查询失败: $e');
        }

        debugPrint('共找到 ${roadList.length} 个播放列表');
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

  /// 解析视频播放地址（用于实际播放）
  Future<String> parseVideoUrl(String pageUrl, String pluginName) async {
    final plugin = _pluginService.getPluginByName(pluginName);
    if (plugin == null) {
      throw Exception('插件不存在: $pluginName');
    }

    if (!plugin.useWebview) {
      return pageUrl;
    }

    debugPrint('========== 开始 WebView 解析 ==========');
    debugPrint('页面URL: $pageUrl');
    debugPrint('插件: $pluginName');
    debugPrint('使用Legacy模式: ${plugin.useLegacyParser}');

    final source = await _videoSourceProvider.resolve(
      pageUrl,
      useLegacyParser: plugin.useLegacyParser,
      timeout: const Duration(seconds: 45),
    );

    debugPrint('========== 最终解析结果 ==========');
    debugPrint('视频流URL: ${source.url}');
    debugPrint('==================================');
    return source.url;
  }
}
