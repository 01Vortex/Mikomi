import 'package:flutter/foundation.dart';
import 'package:mikomi/core/models/video_plugin.dart';
import 'package:mikomi/features/settings/video_play/service/plugin_manager_service.dart';

class VideoPluginService {
  static final VideoPluginService _instance = VideoPluginService._internal();
  factory VideoPluginService() => _instance;
  VideoPluginService._internal();

  final VideoPluginManager _pluginManager = VideoPluginManager();

  List<VideoPlugin> get plugins => _pluginManager.plugins;

  Future<void> initialize() async {
    if (!_pluginManager.isInitialized) {
      await _pluginManager.init();
      debugPrint('视频插件加载完成，共 ${plugins.length} 个');
    }
  }

  VideoPlugin? getPluginByName(String name) {
    return _pluginManager.getPluginByName(name);
  }
}
