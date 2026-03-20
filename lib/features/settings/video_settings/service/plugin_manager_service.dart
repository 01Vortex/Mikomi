import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mikomi/core/models/video_plugin.dart';

/// 视频源(规则)管理器
/// 负责视频源的增删改查和持久化
class VideoPluginManager {
  static final VideoPluginManager _instance = VideoPluginManager._internal();
  factory VideoPluginManager() => _instance;
  VideoPluginManager._internal();

  List<VideoPlugin> _plugins = [];
  Directory? _pluginDirectory;
  static const String _pluginsFileName = 'plugins.json';
  bool _isInitialized = false;

  List<VideoPlugin> get plugins => List.unmodifiable(_plugins);
  bool get isInitialized => _isInitialized;

  /// 初始化插件目录
  Future<void> init() async {
    if (_isInitialized) return;

    final directory = await getApplicationSupportDirectory();
    _pluginDirectory = Directory('${directory.path}/plugins');
    if (!await _pluginDirectory!.exists()) {
      await _pluginDirectory!.create(recursive: true);
    }
    await loadPlugins();

    // 如果没有插件,从assets加载默认插件
    if (_plugins.isEmpty) {
      await loadDefaultPlugins();
    }

    _isInitialized = true;
  }

  /// 从assets加载默认插件
  Future<void> loadDefaultPlugins() async {
    try {
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assets = assetManifest.listAssets();
      final jsonFiles = assets.where(
        (String asset) =>
            asset.startsWith('assets/plugins/') && asset.endsWith('.json'),
      );

      for (var filePath in jsonFiles) {
        try {
          final jsonString = await rootBundle.loadString(filePath);
          final plugin = VideoPlugin.fromJson(jsonDecode(jsonString));
          _plugins.add(plugin);
        } catch (e) {
          print('加载默认插件失败 $filePath: $e');
        }
      }

      if (_plugins.isNotEmpty) {
        await savePlugins();
        print('已加载 ${_plugins.length} 个默认插件');
      }
    } catch (e) {
      print('加载默认插件失败: $e');
    }
  }

  /// 加载所有插件
  Future<void> loadPlugins() async {
    _plugins.clear();
    if (_pluginDirectory == null) return;

    final pluginsFile = File('${_pluginDirectory!.path}/$_pluginsFileName');
    if (await pluginsFile.exists()) {
      try {
        final jsonString = await pluginsFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _plugins = jsonList.map((json) => VideoPlugin.fromJson(json)).toList();
      } catch (e) {
        print('加载插件失败: $e');
      }
    }
  }

  /// 保存所有插件
  Future<void> savePlugins() async {
    if (_pluginDirectory == null) return;

    final pluginsFile = File('${_pluginDirectory!.path}/$_pluginsFileName');
    final jsonList = _plugins.map((plugin) => plugin.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await pluginsFile.writeAsString(jsonString);
  }

  /// 添加或更新插件
  Future<void> updatePlugin(VideoPlugin plugin) async {
    final index = _plugins.indexWhere((p) => p.name == plugin.name);
    if (index != -1) {
      _plugins[index] = plugin;
    } else {
      _plugins.add(plugin);
    }
    await savePlugins();
  }

  /// 删除插件
  Future<void> removePlugin(VideoPlugin plugin) async {
    _plugins.removeWhere((p) => p.name == plugin.name);
    await savePlugins();
  }

  /// 批量删除插件
  Future<void> removePlugins(Set<String> pluginNames) async {
    _plugins.removeWhere((p) => pluginNames.contains(p.name));
    await savePlugins();
  }

  /// 调整插件顺序
  Future<void> reorderPlugins(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final plugin = _plugins.removeAt(oldIndex);
    _plugins.insert(newIndex, plugin);
    await savePlugins();
  }

  /// 根据名称查找插件
  VideoPlugin? getPluginByName(String name) {
    try {
      return _plugins.firstWhere((p) => p.name == name);
    } catch (e) {
      return null;
    }
  }

  /// 导入插件(从Base64编码的JSON)
  Future<bool> importPluginFromBase64(String base64String) async {
    try {
      // 去除可能的 kazumi:// 前缀
      String cleanBase64 = base64String.trim();
      if (cleanBase64.startsWith('kazumi://')) {
        cleanBase64 = cleanBase64.substring('kazumi://'.length);
      }

      // 解码Base64
      final jsonString = utf8.decode(base64Decode(cleanBase64));
      final json = jsonDecode(jsonString);
      final plugin = VideoPlugin.fromJson(json);
      await updatePlugin(plugin);
      return true;
    } catch (e) {
      print('导入插件失败: $e');
      return false;
    }
  }

  /// 导出插件为Base64编码的JSON(带kazumi://前缀)
  String exportPluginToBase64(VideoPlugin plugin) {
    final jsonString = jsonEncode(plugin.toJson());
    final base64 = base64Encode(utf8.encode(jsonString));
    return 'kazumi://$base64';
  }

  /// 重新加载默认插件(用于重置)
  Future<void> reloadDefaultPlugins() async {
    _plugins.clear();
    await loadDefaultPlugins();
  }
}
