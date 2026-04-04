import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_episode_service.dart';
import 'package:mikomi/features/video/services/video_history_service.dart';
import 'package:mikomi/features/video/services/video_parsing_service.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';

class VideoPageService {
  final VideoParsingService _videoParsingService;
  final VideoEpisodeService _videoEpisodeService;
  final VideoHistoryService _videoHistoryService;

  VideoPageService({
    VideoParsingService? videoParsingService,
    VideoEpisodeService? videoEpisodeService,
    VideoHistoryService? videoHistoryService,
  }) : _videoParsingService = videoParsingService ?? VideoParsingService(),
       _videoEpisodeService = videoEpisodeService ?? VideoEpisodeService(),
       _videoHistoryService = videoHistoryService ?? VideoHistoryService();

  bool isDirectStreamUrl(String url) {
    return _videoParsingService.isDirectStreamUrl(url);
  }

  Future<List<Episode>> loadEpisodes({
    required String sourceName,
    required String? animeTitle,
    required String? animeName,
    required int? bangumiId,
  }) {
    return _videoEpisodeService.loadEpisodesWithVideoSource(
      sourceName,
      animeTitle,
      animeName,
      bangumiId,
    );
  }

  Future<String> resolveVideoUrl({
    required String videoPageUrl,
    required String? sourceName,
    required List<Episode> episodes,
    required int currentEpisodeNumber,
  }) {
    return _videoParsingService.resolveVideoUrl(
      videoPageUrl,
      sourceName,
      episodes,
      currentEpisodeNumber,
    );
  }

  Future<String> refreshResolvedVideoUrl({
    required String pageUrl,
    required String sourceName,
    required String previousResolvedUrl,
  }) {
    return _videoParsingService.refreshParsedUrl(
      pageUrl,
      sourceName,
      previousResolvedUrl,
    );
  }

  Future<List<Episode>> switchVideoSource({
    required VideoSource source,
    required String? animeTitle,
    required String? animeName,
    required int? bangumiId,
  }) {
    return _videoEpisodeService.loadEpisodesWithVideoSource(
      source.name,
      animeTitle,
      animeName,
      bangumiId,
    );
  }

  void cancelVideoResolving() {
    _videoParsingService.cancelParsing();
  }

  void saveHistory({
    required int? bangumiId,
    required String title,
    required String? animeTitle,
    required int currentEpisodeNumber,
    required String? currentEpisodeTitle,
    required String? currentSourceName,
    required String lastResolvedVideoUrl,
    required VideoPlaybackService playbackService,
  }) {
    _videoHistoryService.saveHistoryModel(
      bangumiId: bangumiId,
      title: title,
      animeTitle: animeTitle,
      currentEpisode: currentEpisodeNumber,
      currentEpisodeTitle: currentEpisodeTitle,
      currentPluginName: currentSourceName,
      lastResolvedVideoUrl: lastResolvedVideoUrl,
      playerController: playbackService,
    );
  }
}
