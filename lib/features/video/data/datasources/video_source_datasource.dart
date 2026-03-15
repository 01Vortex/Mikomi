import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:mikomi/core/models/road.dart';
import 'package:mikomi/features/video/data/models/video_plugin.dart';

abstract class VideoSourceDatasource {
  Future<List<SearchResult>> search(String keyword, VideoPlugin plugin);
  Future<List<Road>> getRoads(String url, VideoPlugin plugin);
}

class SearchResult {
  final String name;
  final String url;

  SearchResult({required this.name, required this.url});
}

class VideoSourceDatasourceImpl implements VideoSourceDatasource {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  @override
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
                      final gcText = grandChild.text?.trim() ?? '';
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
    } catch (e) {
      debugPrint('搜索失败: $e');
      return [];
    }
  }

  @override
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
    } catch (e, stackTrace) {
      debugPrint('获取剧集列表失败: $e');
      debugPrint('堆栈: $stackTrace');
      return [];
    }
  }
}
