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
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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
    } catch (e) {
      debugPrint('获取剧集列表失败: $e');
      return [];
    }
  }
}
