import 'package:flutter/foundation.dart';
import 'package:mikomi/features/video/services/video_content_service.dart';
import 'package:mikomi/features/video/services/video_source_provider.dart'
    show VideoSourceCancelledException;

class VideoUrlResolverService {
  final VideoContentService _videoSourceRepo = VideoContentService();

  bool isDirectStreamUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') || lower.contains('.mp4');
  }

  Future<String> resolveVideoUrl(
    String url,
    String? pluginName,
    List episodes,
    int currentEpisode,
  ) async {
    try {
      if (episodes.isEmpty) {
        if (isDirectStreamUrl(url)) {
          return url;
        }
        if (pluginName != null && url.isNotEmpty) {
          return await _videoSourceRepo.parseVideoUrl(url, pluginName);
        }
        return url;
      }

      final episodeUrl = episodes
          .firstWhere((ep) => ep.number == currentEpisode)
          .url ??
          url;

      if (pluginName != null) {
        return await _videoSourceRepo.parseVideoUrl(episodeUrl, pluginName);
      }
      return episodeUrl;
    } on VideoSourceCancelledException {
      return '';
    } catch (e) {
      debugPrint('获取视频URL失败: $e');
      rethrow;
    }
  }

  Future<String> refreshParsedUrl(
    String pageUrl,
    String pluginName,
    String lastResolvedUrl,
  ) async {
    try {
      final parsedUrl =
          await _videoSourceRepo.parseVideoUrl(pageUrl, pluginName);
      if (parsedUrl.isEmpty || parsedUrl == lastResolvedUrl) {
        return lastResolvedUrl;
      }
      return parsedUrl;
    } catch (e) {
      debugPrint('静默刷新失败: $e');
      return lastResolvedUrl;
    }
  }

  void cancelParsing() {
    _videoSourceRepo.cancelVideoParsing();
  }
}
