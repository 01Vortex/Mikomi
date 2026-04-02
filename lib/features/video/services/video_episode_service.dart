import 'package:flutter/foundation.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_content_service.dart';
import 'package:mikomi/features/video/services/video_source_provider.dart'
    show CaptchaRequiredException;

class VideoEpisodeService {
  final VideoContentService _videoSourceRepo = VideoContentService();

  Future<List<Episode>> loadEpisodesWithVideoSource(
    String pluginName,
    String? animeTitle,
    String? animeName,
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

      return videoEpisodes;
    } on CaptchaRequiredException catch (e) {
      debugPrint('验证码: $e');
      rethrow;
    } catch (e) {
      debugPrint('加载视频源剧集失败: $e');
      return [];
    }
  }
}
