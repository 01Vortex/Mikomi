import 'package:flutter/foundation.dart';
import 'package:mikomi/features/settings/video_play/service/plugin_manager_service.dart';
import 'package:mikomi/features/video/models/video_plugin.dart';

class VideoSourceRepository {
  final VideoPluginManager _pluginManager;

  VideoSourceRepository({VideoPluginManager? pluginManager})
    : _pluginManager = pluginManager ?? VideoPluginManager();

  Future<void> initialize() async {
    if (!_pluginManager.isInitialized) {
      await _pluginManager.init();
      debugPrint('视频插件加载完成，共 ${_pluginManager.plugins.length} 个');
    }
  }

  List<VideoPlugin> get plugins => _pluginManager.plugins;

  VideoPlugin? getPluginByName(String name) {
    return _pluginManager.getPluginByName(name);
  }
}
