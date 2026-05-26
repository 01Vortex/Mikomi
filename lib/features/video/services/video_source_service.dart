import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/models/video_plugin.dart';
import 'package:mikomi/features/video/origin/bt/rss_bt_resolver.dart';
import 'package:mikomi/features/video/repository/video_source_repository.dart';

class VideoSourceService {
  static final RssBtResolver _btResolver = RssBtResolver();
  static bool _btLoaded = false;
  RssBtResolver get btResolver {
    if (!_btLoaded) {
      _btLoaded = true;
      // 异步加载，但首次调用时可能还没完成。
      // 使用 scheduleMicrotask 确保下一帧完成
      _loadBtSourcesToResolver();
    }
    return _btResolver;
  }

  static Future<void> _loadBtSourcesToResolver() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/plugins/animeko_bt.json');
      final root = jsonDecode(jsonStr) as Map<String, dynamic>;
      final sources = (root['exportedMediaSourceDataList']
              as Map<String, dynamic>?)?['mediaSources'] as List<dynamic>? ??
          const [];
      for (final s in sources) {
        if (s is! Map<String, dynamic>) continue;
        if (s['factoryId'] != 'rss') continue;
        final args = s['arguments'] as Map<String, dynamic>?;
        if (args == null || (args['name'] as String?)?.isEmpty == true) continue;
        _btResolver.registerConfig(args['name'] as String, BtSourceConfig.fromJson(args));
      }
    } catch (_) {}
  }
  final VideoSourceRepository _repository;
  final List<VideoSource> _btSources = [];
  final Map<String, BtSourceConfig> _btConfigs = {};

  VideoSourceService({VideoSourceRepository? repository})
    : _repository = repository ?? VideoSourceRepository();

  Future<void> initialize() async {
    await _repository.initialize();
    await _loadBtSources();
  }

  List<VideoSource> getAvailableSources() {
    final webSources = _repository.plugins
        .map((p) => VideoSource(name: p.name, type: SourceType.web))
        .toList();
    return [...webSources, ..._btSources];
  }

  /// BT 源配置（供 RssBtResolver 使用）
  Map<String, BtSourceConfig> get btConfigs => Map.of(_btConfigs);

  VideoPlugin? getPluginByName(String name) {
    return _repository.getPluginByName(name);
  }

  Future<void> _loadBtSources() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/plugins/animeko_bt.json');
      final root = jsonDecode(jsonStr) as Map<String, dynamic>;
      final sources = (root['exportedMediaSourceDataList']
              as Map<String, dynamic>?)?['mediaSources'] as List<dynamic>? ??
          const [];

      for (final source in sources) {
        if (source is! Map<String, dynamic>) continue;
        if (source['factoryId'] != 'rss') continue;

        final args = source['arguments'] as Map<String, dynamic>?;
        if (args == null) continue;

        final config = BtSourceConfig.fromJson(args);
        if (config.searchUrl.isNotEmpty && config.name.isNotEmpty) {
          _btConfigs[config.name] = config;
          _btResolver.registerConfig(config.name, config);
          _btSources.add(VideoSource(
            name: config.name,
            type: SourceType.bt,
            config: args,
          ));
        }
      }
    } catch (e) {
      // BT 源加载失败不影响 Web 源
      debugPrint('VideoSourceService: BT 源加载失败 - $e');
    }
  }
}
