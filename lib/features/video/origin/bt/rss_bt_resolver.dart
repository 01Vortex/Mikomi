import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/resolver/video_source_resolver.dart';

/// BT RSS 源配置
class BtSourceConfig {
  final String name;
  final String searchUrl;
  final bool filterByEpisodeSort;
  final bool filterBySubjectName;

  const BtSourceConfig({
    required this.name,
    required this.searchUrl,
    this.filterByEpisodeSort = true,
    this.filterBySubjectName = true,
  });

  factory BtSourceConfig.fromJson(Map<String, dynamic> json) {
    final search = json['searchConfig'] as Map<String, dynamic>? ?? {};
    return BtSourceConfig(
      name: json['name'] as String? ?? '',
      searchUrl: search['searchUrl'] as String? ?? '',
      filterByEpisodeSort: search['filterByEpisodeSort'] as bool? ?? true,
      filterBySubjectName: search['filterBySubjectName'] as bool? ?? true,
    );
  }
}

/// RSS BT 解析器——从 RSS feed 搜索磁力链接。
class RssBtResolver implements VideoSourceResolver {
  final Dio _dio;
  final Map<String, BtSourceConfig> _configs;

  RssBtResolver({
    Dio? dio,
    Map<String, BtSourceConfig>? configs,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            )),
        _configs = configs ?? {};

  /// 注册 BT 源配置
  void registerConfig(String sourceName, BtSourceConfig config) {
    _configs[sourceName] = config;
  }

  @override
  bool isDirectStreamUrl(String url) => url.startsWith('magnet:');

  @override
  Future<String> resolveStreamUrl({
    required VideoSource source,
    required Episode episode,
  }) async {
    final config = _configs[source.name];
    if (config == null) {
      throw Exception('BT 源 "${source.name}" 未注册');
    }

    final keyword = _extractKeyword(source);
    final searchUrl = config.searchUrl.replaceAll('{keyword}', Uri.encodeComponent(keyword));

    debugPrint('RssBtResolver: 搜索 "$keyword" → $searchUrl');

    final response = await _dio.get(searchUrl);
    final xml = response.data.toString();

    final items = _parseRssItems(xml);
    debugPrint('RssBtResolver: 解析到 ${items.length} 条 RSS 条目');

    // 按剧集号匹配
    final targetEp = episode.number;
    for (final item in items) {
      final epMatch = _matchEpisode(item['title'] ?? '', targetEp);
      if (epMatch != null) {
        final magnet = item['magnet'] ?? '';
        if (magnet.isNotEmpty) {
          debugPrint('RssBtResolver: 匹配 → ${item['title']}');
          return magnet;
        }
      }
    }

    // 回退：返回第一个有磁力链接的条目
    for (final item in items) {
      final magnet = item['magnet'] ?? '';
      if (magnet.isNotEmpty) {
        debugPrint('RssBtResolver: 回退 → ${item['title']}');
        return magnet;
      }
    }

    throw Exception('BT 源 "${source.name}" 未找到可用资源');
  }

  @override
  Future<String?> refreshStreamUrl({
    required VideoSource source,
    required Episode episode,
    required String lastResolvedUrl,
  }) async {
    try {
      return await resolveStreamUrl(source: source, episode: episode);
    } catch (_) {
      return null;
    }
  }

  @override
  void cancel() {}

  @override
  void dispose() {}

  // ── RSS 解析 ──

  /// 简单 RSS 2.0 解析器（不依赖 xml 包）
  List<Map<String, String>> _parseRssItems(String xml) {
    final items = <Map<String, String>>[];
    final itemPattern = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final titlePattern = RegExp(r'<title>(.*?)</title>', dotAll: true);
    final enclosurePattern = RegExp(
      r'<enclosure[^>]*url="([^"]*)"',
      dotAll: true,
    );

    for (final match in itemPattern.allMatches(xml)) {
      final itemXml = match.group(1) ?? '';
      final titleMatch = titlePattern.firstMatch(itemXml);
      final encMatch = enclosurePattern.firstMatch(itemXml);
      final title = _decodeXmlEntities(titleMatch?.group(1) ?? '');
      final magnet = encMatch?.group(1) ?? '';
      if (title.isNotEmpty) {
        items.add({'title': title, 'magnet': magnet});
      }
    }
    return items;
  }

  // ── 剧集匹配 ──

  /// 从标题匹配剧集号。返回 null 表示不匹配。
  /// 支持格式：第01话, 第1集, EP01, - 01, [01], #01
  static int? _matchEpisode(String title, int targetEp) {
    final patterns = [
      RegExp(r'第\s*0*' + targetEp.toString() + r'\s*[话集]'),
      RegExp(r'[-\[#\s]0*' + targetEp.toString() + r'\s*[-\]\s]'),
      RegExp(r'EP\s*0*' + targetEp.toString(), caseSensitive: false),
      RegExp(r'\b0*' + targetEp.toString() + r'\b'),
    ];
    for (final p in patterns) {
      if (p.hasMatch(title)) return targetEp;
    }
    return null;
  }

  static String _extractKeyword(VideoSource source) {
    final config = source.config;
    if (config != null && config['keyword'] is String) {
      return config['keyword'] as String;
    }
    return source.name;
  }

  static String _decodeXmlEntities(String s) {
    return s
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#039;', "'");
  }
}
