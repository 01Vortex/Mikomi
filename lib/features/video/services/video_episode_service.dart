import 'package:flutter/foundation.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_exception.dart';
import 'package:mikomi/features/video/services/video_service.dart';
import 'package:mikomi/features/video/services/small_title_service.dart';

class VideoEpisodeService {
  final VideoService _videoService = VideoService();
  final SmallTitleService _smallTitleService = SmallTitleService();

  Future<List<Episode>> loadEpisodesWithVideoSource(
    String pluginName,
    String? animeTitle,
    String? animeName,
    int? bangumiId,
  ) async {
    if (animeTitle == null) return [];

    try {
      var videoEpisodes = await _videoService
          .episodeGateway(animeTitle, pluginName)
          .timeout(const Duration(seconds: 60), onTimeout: () => []);

      if (videoEpisodes.isEmpty &&
          animeName != null &&
          animeName != animeTitle) {
        videoEpisodes = await _videoService
            .episodeGateway(animeName, pluginName)
            .timeout(const Duration(seconds: 60), onTimeout: () => []);
      }

      return await _smallTitleService.applyEpisodeSmallTitles(
        episodes: videoEpisodes,
        bangumiId: bangumiId,
        animeTitle: animeTitle,
        animeName: animeName,
      );
    } on VideoCaptchaRequiredException catch (e) {
      debugPrint('验证码: $e');
      rethrow;
    } catch (e) {
      debugPrint('加载视频源剧集失败: $e');
      return [];
    }
  }
}
