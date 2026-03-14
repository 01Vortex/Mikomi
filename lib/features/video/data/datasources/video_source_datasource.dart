import 'package:dio/dio.dart';
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
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  @override
  Future<List<SearchResult>> search(String keyword, VideoPlugin plugin) async {
    try {
      final searchUrl = plugin.searchURL.replaceAll('@keyword', keyword);
      final url = searchUrl.startsWith('http')
          ? searchUrl
          : plugin.baseURL + searchUrl;

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'referer': '${plugin.baseURL}/',
            'user-agent': plugin.userAgent.isNotEmpty
                ? plugin.userAgent
                : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.data);
        final htmlElement = document.documentElement;

        if (htmlElement == null) {
          print('HTML解析失败：documentElement为null');
          return [];
        }

        final results = <SearchResult>[];

        try {
          final searchNodes = htmlElement.queryXPath(plugin.searchList).nodes;

          for (var node in searchNodes) {
            try {
              final nameNodes = node.queryXPath(plugin.searchName).nodes;
              final resultNodes = node.queryXPath(plugin.searchResult).nodes;

              if (nameNodes.isNotEmpty && resultNodes.isNotEmpty) {
                final nameNode = nameNodes.first.node;
                final resultNode = resultNodes.first.node;

                final name = nameNode.text?.trim() ?? '';
                final href = resultNode.attributes['href'] ?? '';

                if (name.isNotEmpty && href.isNotEmpty) {
                  final fullUrl = href.startsWith('http')
                      ? href
                      : plugin.baseURL + href;
                  results.add(SearchResult(name: name, url: fullUrl));
                }
              }
            } catch (e) {
              print('解析搜索结果项失败: $e');
            }
          }
        } catch (e) {
          print('XPath查询失败: $e');
        }

        return results;
      }
      return [];
    } catch (e) {
      print('搜索失败: $e');
      return [];
    }
  }

  @override
  Future<List<Road>> getRoads(String url, VideoPlugin plugin) async {
    try {
      final fullUrl = url.startsWith('http') ? url : plugin.baseURL + url;

      final response = await _dio.get(
        fullUrl,
        options: Options(
          headers: {
            'referer': '${plugin.baseURL}/',
            'user-agent': plugin.userAgent.isNotEmpty
                ? plugin.userAgent
                : 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );

      if (response.statusCode == 200) {
        final document = html_parser.parse(response.data);
        final htmlElement = document.documentElement;

        if (htmlElement == null) {
          print('HTML解析失败：documentElement为null');
          return [];
        }

        final roadList = <Road>[];

        try {
          final roadNodes = htmlElement.queryXPath(plugin.chapterRoads).nodes;

          int count = 1;
          for (var roadNode in roadNodes) {
            try {
              final chapterNodes = roadNode
                  .queryXPath(plugin.chapterResult)
                  .nodes;

              final chapterUrls = <String>[];
              final chapterNames = <String>[];

              for (var chapterNode in chapterNodes) {
                final node = chapterNode.node;
                final href = node.attributes['href'] ?? '';
                final name = node.text?.trim() ?? '';

                if (href.isNotEmpty && name.isNotEmpty) {
                  final fullChapterUrl = href.startsWith('http')
                      ? href
                      : plugin.baseURL + href;
                  chapterUrls.add(fullChapterUrl);
                  chapterNames.add(name.replaceAll(RegExp(r'\s+'), ''));
                }
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
            } catch (e) {
              print('解析播放列表失败: $e');
            }
          }
        } catch (e) {
          print('XPath查询失败: $e');
        }

        return roadList;
      }
      return [];
    } catch (e) {
      print('获取剧集列表失败: $e');
      return [];
    }
  }
}
