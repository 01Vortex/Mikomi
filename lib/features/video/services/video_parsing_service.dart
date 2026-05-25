import 'package:flutter/foundation.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/exception/video_exception.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/resolver/web_source_resolver.dart';
import 'package:mikomi/features/video/services/resolver/video_source_resolver.dart';

/// 视频流解析路由器——根据 [VideoSource.type] 委托给对应的 [VideoSourceResolver]。
///
/// 当前仅注册了 [WebSourceResolver]（Web 爬虫）。
/// BT 源接入时在此注册 [BtSourceResolver]。
class VideoParsingService {
  final WebSourceResolver _webResolver;

  VideoParsingService({
    WebSourceResolver? webResolver,
  }) : _webResolver = webResolver ?? WebSourceResolver();

  /// 注册 BT 解析器时在此添加
  // late final BtSourceResolver _btResolver;

  VideoSourceResolver _resolverFor(VideoSource source) {
    return switch (source.type) {
      SourceType.web => _webResolver,
      SourceType.bt => throw UnimplementedError('BT 源待实现'),
    };
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

  void dispose() => _webResolver.dispose();
}
