import 'package:flutter/foundation.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:mikomi/core/services/bangumi_episodes_service.dart';
import 'package:mikomi/features/video/services/video_content_service.dart';
import 'package:mikomi/features/video/services/video_source_provider.dart'
    show CaptchaRequiredException;

class VideoEpisodeService {
  final BangumiEpisodesService _episodesService = BangumiEpisodesService();
  final VideoContentService _videoSourceRepo = VideoContentService();

  Future<List<Episode>> loadEpisodesWithVideoSource(
    String pluginName,
    String? animeTitle,
    String? animeName,
    int? bangumiId,
  ) async {
    if (animeTitle == null) return [];
    try {
      var videoEpisodes = await _videoSourceRepo
          .searchAndGetEpisodes(animeTitle, pluginName)
          .timeout(const Duration(seconds: 60), onTimeout: () => []);

      if (videoEpisodes.isEmpty &&
          animeName != null &&
          animeName != animeTitle) {
        videoEpisodes = await _videoSourceRepo
            .searchAndGetEpisodes(animeName, pluginName)
            .timeout(const Duration(seconds: 60), onTimeout: () => []);
      }

      if (videoEpisodes.isEmpty) return [];

      List<Episode>? bangumiEpisodes;
      if (bangumiId != null) {
        try {
          bangumiEpisodes = await _episodesService
              .getEpisodesBySubjectId(bangumiId)
              .timeout(const Duration(seconds: 15), onTimeout: () => []);
        } catch (e) {
          debugPrint('获取Bangumi剧集失败: $e');
        }
      }

      final mergedEpisodes = <Episode>[];
      for (int i = 0; i < videoEpisodes.length; i++) {
        final videoEp = videoEpisodes[i];
        String? title = videoEp.title;
        if (bangumiEpisodes != null && i < bangumiEpisodes.length) {
          title = bangumiEpisodes[i].title;
        }
        mergedEpisodes.add(
          Episode(number: videoEp.number, title: title, url: videoEp.url),
        );
      }

      return mergedEpisodes;
    } on CaptchaRequiredException catch (e) {
      debugPrint('验证码: $e');
      rethrow;
    } catch (e) {
      debugPrint('加载视频源剧集失败: $e');
      return [];
    }
  }

  Future<List<Episode>> loadBangumiEpisodes(int bangumiId) async {
    try {
      return await _episodesService
          .getEpisodesBySubjectId(bangumiId)
          .timeout(const Duration(seconds: 10), onTimeout: () => []);
    } catch (e) {
      debugPrint('加载Bangumi剧集失败: $e');
      return [];
    }
  }
}
