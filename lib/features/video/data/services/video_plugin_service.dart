import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:mikomi/features/video/data/models/video_plugin.dart';

class VideoPluginService {
  static final VideoPluginService _instance = VideoPluginService._internal();
  factory VideoPluginService() => _instance;
  VideoPluginService._internal();

  final List<VideoPlugin> _plugins = [];
  bool _initialized = false;

  List<VideoPlugin> get plugins => List.unmodifiable(_plugins);

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // 加载所有插件配置
      final pluginNames = ['7sefun', 'AGE', 'DM84'];

      for (final name in pluginNames) {
        try {
          final jsonString = await rootBundle.loadString(
            'assets/plugins/$name.json',
          );
          final jsonData = json.decode(jsonString);
          final plugin = VideoPlugin.fromJson(jsonData);
          _plugins.add(plugin);
        } catch (e) {
          print('加载插件 $name 失败: $e');
        }
      }

      _initialized = true;
      print('视频插件加载完成，共 ${_plugins.length} 个');
    } catch (e) {
      print('初始化视频插件失败: $e');
    }
  }

  VideoPlugin? getPluginByName(String name) {
    try {
      return _plugins.firstWhere((plugin) => plugin.name == name);
    } catch (e) {
      return null;
    }
  }
}
