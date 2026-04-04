import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mikomi/features/video/models/video_plugin.dart';

/// 视频源(规则)管理器
/// 负责视频源的增删改查和持久化
class VideoPluginManager {
  static final VideoPluginManager _instance = VideoPluginManager._internal();
  factory VideoPluginManager() => _instance;
  VideoPluginManager._internal();

  final List<VideoPlugin> _plugins = [];
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
      final jsonFiles = assets
          .where(
            (String asset) =>
                asset.startsWith('assets/plugins/') && asset.endsWith('.json'),
          )
          .toList();

      if (jsonFiles.isEmpty) {
        debugPrint('未找到默认插件');
        return;
      }

      var importedCount = 0;
      for (final filePath in jsonFiles) {
        try {
          final jsonString = await rootBundle.loadString(filePath);
          final plugin = _decodePluginJson(jsonString);
          if (_mergePlugin(plugin)) {
            importedCount++;
          }
        } catch (e) {
          debugPrint('加载默认插件失败 $filePath: $e');
        }
      }

      if (importedCount > 0) {
        await savePlugins();
      }
      debugPrint('已加载 $importedCount 个默认插件');
    } catch (e) {
      debugPrint('加载默认插件失败: $e');
    }
  }

  /// 加载所有插件
  Future<void> loadPlugins() async {
    _plugins.clear();
    if (_pluginDirectory == null) {
      return;
    }

    final pluginsFile = File('${_pluginDirectory!.path}/$_pluginsFileName');
    if (!await pluginsFile.exists()) {
      return;
    }

    try {
      final jsonString = await pluginsFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final loadedPlugins = jsonList.map((json) => VideoPlugin.fromJson(json));
      for (final plugin in loadedPlugins) {
        _mergePlugin(plugin);
      }
    } catch (e) {
      debugPrint('加载插件失败: $e');
      _plugins.clear();
    }
  }

  /// 保存所有插件
  Future<void> savePlugins() async {
    if (_pluginDirectory == null) return;

    try {
      if (!await _pluginDirectory!.exists()) {
        await _pluginDirectory!.create(recursive: true);
      }
      final pluginsFile = File('${_pluginDirectory!.path}/$_pluginsFileName');
      final jsonList = _plugins.map((plugin) => plugin.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await pluginsFile.writeAsString(jsonString);
    } catch (e) {
      debugPrint('保存插件失败: $e');
    }
  }

  /// 添加或更新插件
  Future<void> updatePlugin(VideoPlugin plugin) async {
    _mergePlugin(plugin);
    await savePlugins();
  }

  /// 删除插件
  Future<void> removePlugin(VideoPlugin plugin) async {
    _plugins.removeWhere((p) => p.id == plugin.id);
    await savePlugins();
  }

  /// 批量删除插件
  Future<void> removePlugins(Set<String> pluginIds) async {
    _plugins.removeWhere((p) => pluginIds.contains(p.id));
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

  /// 根据ID查找插件
  VideoPlugin? getPluginById(String id) {
    try {
      return _plugins.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 导入插件(从Base64编码的JSON)
  Future<bool> importPluginFromBase64(String base64String) async {
    try {
      String cleanBase64 = base64String.trim();
      for (final prefix in ['mikomi://', 'kazumi://', 'mikomi:', 'kazumi:']) {
        if (cleanBase64.startsWith(prefix)) {
          cleanBase64 = cleanBase64.substring(prefix.length);
          break;
        }
      }
      final jsonString = utf8.decode(base64Decode(cleanBase64));
      return await importPluginFromJsonString(jsonString);
    } catch (e) {
      debugPrint('导入插件失败: $e');
      return false;
    }
  }

  Future<bool> importPluginFromJsonString(String jsonString) async {
    try {
      final plugin = _decodePluginJson(jsonString);
      _mergePlugin(plugin);
      await savePlugins();
      return true;
    } catch (e) {
      debugPrint('导入 JSON 插件失败: $e');
      return false;
    }
  }

  Future<bool> importPluginFromJsonFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return false;
      }
      final jsonString = await file.readAsString();
      return await importPluginFromJsonString(jsonString);
    } catch (e) {
      debugPrint('导入插件文件失败: $e');
      return false;
    }
  }

  /// 导出插件为Base64编码的JSON(带mikomi://前缀)
  String exportPluginToBase64(VideoPlugin plugin) {
    final jsonString = jsonEncode(plugin.toJson());
    final base64 = base64Encode(utf8.encode(jsonString));
    return 'mikomi://$base64';
  }

  Future<void> reloadDefaultPlugins() async {
    _plugins.clear();
    await loadDefaultPlugins();
  }

  VideoPlugin _decodePluginJson(String jsonString) {
    final json = jsonDecode(jsonString);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('插件 JSON 格式不正确');
    }
    return VideoPlugin.fromJson(json);
  }

  bool _mergePlugin(VideoPlugin plugin) {
    final normalizedName = plugin.name.trim().toLowerCase();
    final normalizedBaseUrl = plugin.baseURL.trim().toLowerCase();

    final index = _plugins.indexWhere((item) {
      if (item.id == plugin.id) {
        return true;
      }
      return item.name.trim().toLowerCase() == normalizedName &&
          item.baseURL.trim().toLowerCase() == normalizedBaseUrl;
    });

    if (index == -1) {
      _plugins.add(plugin);
      return true;
    }

    final existing = _plugins[index];
    _plugins[index] = plugin.copyWith(id: existing.id);
    return false;
  }
}
