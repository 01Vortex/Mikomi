import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:mikomi/core/models/video_plugin.dart';

class PluginHTTPItem {
  final String name;
  final String version;
  final String api;
  final bool useNativePlayer;
  final bool antiCrawlerEnabled;
  final int lastUpdate;

  PluginHTTPItem({
    required this.name,
    required this.version,
    required this.api,
    required this.useNativePlayer,
    required this.antiCrawlerEnabled,
    required this.lastUpdate,
  });

  factory PluginHTTPItem.fromJson(Map<String, dynamic> json) {
    return PluginHTTPItem(
      name: json['name'] ?? '',
      version: json['version'] ?? '',
      api: json['api'] ?? '1',
      useNativePlayer: json['useNativePlayer'] ?? true,
      antiCrawlerEnabled: json['antiCrawlerConfig']?['enabled'] ?? false,
      lastUpdate: json['lastUpdate'] ?? 0,
    );
  }
}

class PluginShopService {
  static const String _pluginShopUrl =
      'https://raw.githubusercontent.com/Predidit/KazumiRules/main/';
  static const String _pluginShopMirrorUrl =
      'https://ghfast.top/https://raw.githubusercontent.com/Predidit/KazumiRules/main/';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      responseType: ResponseType.plain,
    ),
  );

  Future<List<PluginHTTPItem>> getPluginList() async {
    for (final baseUrl in [_pluginShopMirrorUrl, _pluginShopUrl]) {
      try {
        final response = await _dio.get<String>('${baseUrl}index.json');
        final List<dynamic> jsonList =
            jsonDecode(response.data!) as List<dynamic>;
        return jsonList
            .map((item) =>
                PluginHTTPItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('获取云端插件列表失败 ($baseUrl): $e');
      }
    }
    return [];
  }

  Future<VideoPlugin?> getPlugin(String name) async {
    for (final baseUrl in [_pluginShopMirrorUrl, _pluginShopUrl]) {
      try {
        final response = await _dio.get<String>('$baseUrl$name.json');
        final json =
            jsonDecode(response.data!) as Map<String, dynamic>;
        return VideoPlugin.fromJson(json);
      } catch (e) {
        print('获取云端插件失败 ($baseUrl): $e');
      }
    }
    return null;
  }
}
