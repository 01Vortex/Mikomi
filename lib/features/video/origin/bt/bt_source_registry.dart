import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/origin/bt/rss_bt_resolver.dart';

/// BT 源注册中心——从 animeko 格式 JSON 加载 BT 源配置。
class BtSourceRegistry {
  final Map<String, BtSourceConfig> _configs = {};

  RssBtResolver buildResolver() => RssBtResolver(configs: Map.of(_configs));

  /// 从 assets 加载 animeko 格式的 BT JSON 文件
  Future<void> loadFromAsset(String assetPath) async {
    final jsonStr = await rootBundle.loadString(assetPath);
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
      if (config.searchUrl.isNotEmpty) {
        _configs[config.name] = config;
      }
    }
  }

  /// 获取所有已注册 BT 源名称
  List<VideoSource> get sources => _configs.keys
      .map((name) => VideoSource(name: name, type: SourceType.bt))
      .toList();
}
