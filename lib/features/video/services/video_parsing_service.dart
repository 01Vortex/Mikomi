import 'package:flutter/foundation.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/exception/video_exception.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/origin/bt/rss_bt_resolver.dart';
import 'package:mikomi/features/video/services/resolver/web_source_resolver.dart';
import 'package:mikomi/features/video/services/resolver/video_source_resolver.dart';

/// 视频流解析路由器——根据 [SourceType] 委托给对应的 [VideoSourceResolver]。
class VideoParsingService {
  final WebSourceResolver _webResolver;
  RssBtResolver? _btResolver;

  VideoParsingService({
    WebSourceResolver? webResolver,
    RssBtResolver? btResolver,
  }) : _webResolver = webResolver ?? WebSourceResolver(),
       _btResolver = btResolver;

  /// 注册 BT 解析器
  void registerBtResolver(RssBtResolver resolver) => _btResolver = resolver;

  VideoSourceResolver _resolverFor(SourceType type) => switch (type) {
    SourceType.web => _webResolver,
    SourceType.bt => _btResolver ?? (throw StateError('BT 解析器未注册')),
  };

  // ── 新 API（按 source 路由） ──

  /// 解析视频流 URL（新接口——按 [VideoSource] 路由）
  Future<String> resolveWithSource({
    required VideoSource source,
    required Episode episode,
  }) async {
    final resolver = _resolverFor(source.type);
    return resolver.resolveStreamUrl(source: source, episode: episode);
  }

  // ── 兼容旧 API（保持 VideoResolveController 不变） ──

  bool isDirectStreamUrl(String url) => _webResolver.isDirectStreamUrl(url);

  Future<String> resolveVideoUrl(
    String url,
    String? pluginName,
    List<Episode> episodes,
    int currentEpisode,
  ) async {
    try {
      if (episodes.isEmpty) {
        if (isDirectStreamUrl(url)) return url;
        if (pluginName != null && url.isNotEmpty) {
          return _webResolver.resolveFromPage(pluginName, url);
        }
        return url;
      }
      final episodeUrl = episodes
              .firstWhere((ep) => ep.number == currentEpisode)
              .url ??
          url;
      if (pluginName != null) {
        return _webResolver.resolveFromPage(pluginName, episodeUrl);
      }
      return episodeUrl;
    } on VideoStreamCancelledException {
      return '';
    } catch (e) {
      debugPrint('VideoParsingService: 获取视频URL失败 - $e');
      rethrow;
    }
  }

  Future<String> refreshParsedUrl(
    String pageUrl,
    String pluginName,
    String lastResolvedUrl,
  ) async {
    try {
      final parsedUrl = await _webResolver.resolveFresh(pluginName, pageUrl);
      if (parsedUrl.isEmpty || parsedUrl == lastResolvedUrl) {
        return lastResolvedUrl;
      }
      return parsedUrl;
    } catch (e) {
      debugPrint('VideoParsingService: 静默刷新失败 - $e');
      return lastResolvedUrl;
    }
  }

  void cancelParsing() => _webResolver.cancel();

  void dispose() {
    _webResolver.dispose();
    _btResolver?.dispose();
  }
}
