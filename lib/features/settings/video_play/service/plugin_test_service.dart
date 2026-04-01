import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:mikomi/features/video/models/video_plugin.dart';
import 'package:mikomi/core/models/road.dart';
import 'package:mikomi/features/video/services/video_content_service.dart';

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

  /// 重置 Dio 实例（清除 cookie 等状态）
  void resetDio() => _initDio();

  /// 获取当前 Dio 实例（供外部注入 cookie）
  Dio getDio() => _dio;

  /// 取消当前请求
  void cancel(String reason) {
    cancelToken?.cancel(reason);
    cancelToken = null;
  }

  /// 构造搜索 URL
  String buildSearchUrl(String keyword) {
    final s = plugin.searchURL.replaceAll('@keyword', keyword);
    if (s.startsWith('http')) return s;
    if (s.startsWith('/')) return plugin.baseURL + s;
    return '${plugin.baseURL}/$s';
  }

  /// 判断 HTML 是否为验证码拦截页
  bool looksLikeCaptcha(String html) {
    final lower = html.toLowerCase();
    return lower.contains('captcha') ||
        lower.contains('验证码') ||
        lower.contains('verify') ||
        lower.contains('人机验证') ||
        lower.contains('geetest') ||
        lower.contains('turnstile') ||
        lower.contains('smart-verify') ||
        lower.contains('verify-panel');
  }

  /// 获取页面 HTML，返回 null 表示请求被取消或失败
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

  /// 解析搜索结果列表
  List<SearchResult> parseSearchResults(String html) {
    try {
      final doc = html_parser.parse(html).documentElement;
      if (doc == null) return [];
      final results = <SearchResult>[];
      for (var node in doc.queryXPath(plugin.searchList).nodes) {
        try {
          final nameNode = node.queryXPath(plugin.searchName).node;
          final resultNode = node.queryXPath(plugin.searchResult).node;
          if (nameNode == null || resultNode == null) continue;
          final name = nameNode.text?.trim() ?? '';
          final href = resultNode.attributes['href'] ?? '';
          if (name.isEmpty || href.isEmpty) continue;
          final fullUrl = href.startsWith('http')
              ? href
              : href.startsWith('/')
                  ? plugin.baseURL + href
                  : '${plugin.baseURL}/$href';
          results.add(SearchResult(name: name, url: fullUrl));
        } catch (_) {}
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// 解析章节/播放列表
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
          final fullUrl = href.startsWith('http')
              ? href
              : href.startsWith('/')
                  ? plugin.baseURL + href
                  : '${plugin.baseURL}/$href';
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
