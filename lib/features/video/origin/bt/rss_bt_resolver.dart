import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/origin/bt/libtorrent_stream_service.dart';
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

/// RSS BT 解析器——RSS 搜索 + webtor.io 流播放。
class RssBtResolver implements VideoSourceResolver {
  final Dio _dio;
  final LibtorrentStreamService _streamService;
  final Map<String, BtSourceConfig> _configs;

  RssBtResolver({
    Dio? dio,
    LibtorrentStreamService? streamService,
    Map<String, BtSourceConfig>? configs,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            )),
        _streamService = streamService ?? LibtorrentStreamService(),
        _configs = configs ?? {};

  void registerConfig(String sourceName, BtSourceConfig config) {
    _configs[sourceName] = config;
  }

  @override
  bool isDirectStreamUrl(String url) =>
      url.startsWith('http://127.0.0.1') || url.startsWith('magnet:');

  @override
  Future<String> resolveStreamUrl({
    required VideoSource source,
    required Episode episode,
  }) async {
    final items = await _fetchRssItems(source);
    final targetEp = episode.number;

    for (final item in items) {
      if (_matchEpisode(item.title, targetEp) != null && item.magnet.isNotEmpty) {
        final localUrl = await _streamService.createStream(item.magnet);
        if (localUrl != null) return localUrl;
      }
    }

    for (final item in items) {
      if (item.magnet.isNotEmpty) {
        final localUrl = await _streamService.createStream(item.magnet);
        if (localUrl != null) return localUrl;
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

  // ── RSS 剧集列表 ──

  Future<List<RssEpisode>> fetchEpisodes(VideoSource source) async {
    final items = await _fetchRssItems(source);
    final episodes = <RssEpisode>[];

    for (final item in items) {
      final epNum = _extractEpisodeNumber(item.title);
      if (epNum > 0 && item.magnet.isNotEmpty) {
        episodes.add(RssEpisode(
          number: epNum,
          title: item.title,
          magnet: item.magnet,
        ));
      }
    }

    episodes.sort((a, b) => a.number.compareTo(b.number));
    return episodes;
  }

  // ── 内部 ──

  Future<List<_RssItem>> _fetchRssItems(VideoSource source) async {
    final config = _configs[source.name];
    if (config == null) throw Exception('BT 源 "${source.name}" 未注册');

    final keyword = source.config?['keyword'] as String? ?? source.name;
    final searchUrl =
        config.searchUrl.replaceAll('{keyword}', Uri.encodeComponent(keyword));

    debugPrint('RssBtResolver: RSS → $searchUrl');
    final response = await _dio.get(searchUrl);
    return _parseRss(response.data.toString());
  }

  List<_RssItem> _parseRss(String xml) {
    final items = <_RssItem>[];
    final itemP = RegExp(r'<item>(.*?)</item>', dotAll: true);
    final titleP = RegExp(r'<title>(.*?)</title>', dotAll: true);
    final encP = RegExp(r'<enclosure[^>]*url="([^"]*)"', dotAll: true);

    for (final m in itemP.allMatches(xml)) {
      final t = titleP.firstMatch(m.group(1) ?? '');
      final e = encP.firstMatch(m.group(1) ?? '');
      final title = _decode(t?.group(1) ?? '');
      final magnet = e?.group(1) ?? '';
      if (title.isNotEmpty) items.add(_RssItem(title: title, magnet: magnet));
    }
    return items;
  }

  static int? _matchEpisode(String title, int targetEp) {
    for (final p in [
      RegExp(r'第\s*0*' + targetEp.toString() + r'\s*[话集]'),
      RegExp(r'[-\[#\s]0*' + targetEp.toString() + r'\b'),
      RegExp(r'EP\s*0*' + targetEp.toString(), caseSensitive: false),
    ]) {
      if (p.hasMatch(title)) return targetEp;
    }
    return null;
  }

  static int _extractEpisodeNumber(String title) {
    for (final p in [
      RegExp(r'第\s*0*(\d+)\s*[话集]'),
      RegExp(r'[-\[#\s]0*(\d+)\b'),
      RegExp(r'EP\s*0*(\d+)', caseSensitive: false),
    ]) {
      final m = p.firstMatch(title);
      if (m != null) {
        final n = int.tryParse(m.group(1) ?? '');
        if (n != null && n > 0 && n < 2000) return n;
      }
    }
    return 0;
  }

  static String _decode(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"');
}

class _RssItem {
  final String title;
  final String magnet;
  const _RssItem({required this.title, required this.magnet});
}

class RssEpisode {
  final int number;
  final String title;
  final String magnet;

  const RssEpisode({
    required this.number,
    required this.title,
    required this.magnet,
  });
}
