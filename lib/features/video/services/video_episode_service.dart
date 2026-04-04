import 'package:flutter/foundation.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/repository/video_episode_repository.dart';
import 'package:mikomi/features/video/exception/video_exception.dart';

class VideoEpisodeService {
  final VideoEpisodeRepository _repository;

  VideoEpisodeService({VideoEpisodeRepository? repository})
    : _repository = repository ?? VideoEpisodeRepository();

  Future<List<Episode>> loadEpisodes({
    required String sourceName,
    required String? animeTitle,
    required String? animeName,
    required int? bangumiId,
  }) async {
    if (animeTitle == null) return [];

    try {
      final episodes = await _repository.fetchEpisodes(
        sourceName: sourceName,
        animeTitle: animeTitle,
        animeName: animeName,
      );

      return _applyEpisodeSmallTitles(
        episodes: episodes,
        bangumiId: bangumiId,
        animeTitle: animeTitle,
        animeName: animeName,
      );
    } on VideoCaptchaRequiredException {
      rethrow;
    } catch (e) {
      debugPrint('加载视频源剧集失败: $e');
      return [];
    }
  }

  Future<List<Episode>> _applyEpisodeSmallTitles({
    required List<Episode> episodes,
    int? bangumiId,
    String? animeTitle,
    String? animeName,
  }) async {
    return episodes;
  }
}
