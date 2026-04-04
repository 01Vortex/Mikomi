import 'package:flutter/foundation.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_episode_service.dart';
import 'package:mikomi/features/video/services/video_history_service.dart';
import 'package:mikomi/features/video/services/video_parsing_service.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/video_state_manager.dart';

class VideoPageInitializeResult {
  final Future<String> currentVideoUrlFuture;
  final bool shouldLoadEpisodes;

  const VideoPageInitializeResult({
    required this.currentVideoUrlFuture,
    required this.shouldLoadEpisodes,
  });
}

class VideoPageEpisodeLoadResult {
  final bool didLoadEpisodes;
  final bool shouldRefreshParsedUrlSilently;
  final bool shouldUpdateCurrentVideoUrl;

  const VideoPageEpisodeLoadResult({
    required this.didLoadEpisodes,
    required this.shouldRefreshParsedUrlSilently,
    required this.shouldUpdateCurrentVideoUrl,
  });
}

class VideoPageSourceSwitchResult {
  final bool didLoadEpisodes;

  const VideoPageSourceSwitchResult({required this.didLoadEpisodes});
}

class VideoPageService {
  final VideoParsingService _videoParsingService;
  final VideoEpisodeService _episodeService;
  final VideoHistoryService _historyService;

  VideoPageService({
    VideoParsingService? videoParsingService,
    VideoEpisodeService? episodeService,
    VideoHistoryService? historyService,
  }) : _videoParsingService = videoParsingService ?? VideoParsingService(),
       _episodeService = episodeService ?? VideoEpisodeService(),
       _historyService = historyService ?? VideoHistoryService();

  void initializeState({
    required VideoStateManager state,
    required int currentEpisode,
    required List<Episode> episodes,
    required String videoUrl,
    required String? pluginName,
  }) {
    state.currentEpisode = currentEpisode;
    state.episodes = episodes;
    state.videoUrl = videoUrl;
    state.currentPluginName = pluginName;
  }

  VideoPageInitializeResult initializeVideoUrl({
    required VideoStateManager state,
    required String? animeTitle,
  }) {
    final shouldLoadEpisodes =
        state.episodes.isEmpty && state.currentPluginName != null;

    if (state.episodes.isEmpty &&
        state.currentPluginName != null &&
        animeTitle != null) {
      if (state.videoUrl.isNotEmpty) {
        if (_videoParsingService.isDirectStreamUrl(state.videoUrl)) {
          state.isUsingCachedPlayUrl = true;
          state.shouldParseAfterEpisodesLoaded = true;
          state.lastResolvedVideoUrl = state.videoUrl;
          return VideoPageInitializeResult(
            currentVideoUrlFuture: Future.value(state.videoUrl),
            shouldLoadEpisodes: shouldLoadEpisodes,
          );
        }
        return VideoPageInitializeResult(
          currentVideoUrlFuture: getCurrentVideoUrl(state),
          shouldLoadEpisodes: shouldLoadEpisodes,
        );
      }

      state.shouldParseAfterEpisodesLoaded = true;
      return VideoPageInitializeResult(
        currentVideoUrlFuture: Future.value(''),
        shouldLoadEpisodes: shouldLoadEpisodes,
      );
    }

    return VideoPageInitializeResult(
      currentVideoUrlFuture: getCurrentVideoUrl(state),
      shouldLoadEpisodes: shouldLoadEpisodes,
    );
  }

  void beginEpisodeLoading(VideoStateManager state) {
    state.isLoadingEpisodes = true;
  }

  void endEpisodeLoading(VideoStateManager state) {
    state.isLoadingEpisodes = false;
  }

  void resetResolveState(VideoStateManager state) {
    state.showTimeoutHint = false;
    state.hasParseError = false;
  }

  void beginSourceSwitch(VideoStateManager state) {
    cancelParsing();
    state.isLoadingEpisodes = true;
  }

  Future<VideoPageEpisodeLoadResult> loadEpisodesInBackground({
    required VideoStateManager state,
    required String? animeTitle,
    required String? animeName,
    required int? bangumiId,
  }) async {
    if (animeTitle == null || state.currentPluginName == null) {
      return const VideoPageEpisodeLoadResult(
        didLoadEpisodes: false,
        shouldRefreshParsedUrlSilently: false,
        shouldUpdateCurrentVideoUrl: false,
      );
    }

    try {
      final episodes = await _episodeService.loadEpisodesWithVideoSource(
        state.currentPluginName!,
        animeTitle,
        animeName,
        bangumiId,
      );

      if (episodes.isEmpty) {
        return const VideoPageEpisodeLoadResult(
          didLoadEpisodes: false,
          shouldRefreshParsedUrlSilently: false,
          shouldUpdateCurrentVideoUrl: false,
        );
      }

      state.episodes = episodes;
      if (state.currentEpisode > state.episodes.length) {
        state.currentEpisode = 1;
      }

      final shouldRefreshParsedUrlSilently =
          state.shouldParseAfterEpisodesLoaded && state.isUsingCachedPlayUrl;
      final shouldUpdateCurrentVideoUrl =
          state.shouldParseAfterEpisodesLoaded && !state.isUsingCachedPlayUrl;

      state.shouldParseAfterEpisodesLoaded = false;
      if (state.isUsingCachedPlayUrl) {
        state.isUsingCachedPlayUrl = false;
      }

      return VideoPageEpisodeLoadResult(
        didLoadEpisodes: true,
        shouldRefreshParsedUrlSilently: shouldRefreshParsedUrlSilently,
        shouldUpdateCurrentVideoUrl: shouldUpdateCurrentVideoUrl,
      );
    } catch (e) {
      debugPrint('后台加载剧集失败: $e');
      return const VideoPageEpisodeLoadResult(
        didLoadEpisodes: false,
        shouldRefreshParsedUrlSilently: false,
        shouldUpdateCurrentVideoUrl: false,
      );
    }
  }

  Future<String> refreshParsedUrlSilently(VideoStateManager state) async {
    if (state.currentPluginName == null || state.episodes.isEmpty) {
      return state.lastResolvedVideoUrl;
    }

    try {
      final pageUrl =
          state.episodes
              .firstWhere((ep) => ep.number == state.currentEpisode)
              .url ??
          state.videoUrl;
      final parsedUrl = await _videoParsingService.refreshParsedUrl(
        pageUrl,
        state.currentPluginName!,
        state.lastResolvedVideoUrl,
      );
      if (parsedUrl.isNotEmpty) {
        state.lastResolvedVideoUrl = parsedUrl;
      }
      return state.lastResolvedVideoUrl;
    } catch (e) {
      debugPrint('静默刷新失败: $e');
      return state.lastResolvedVideoUrl;
    }
  }

  Future<String> getCurrentVideoUrl(VideoStateManager state) async {
    try {
      final url = await _videoParsingService.resolveVideoUrl(
        state.videoUrl,
        state.currentPluginName,
        state.episodes,
        state.currentEpisode,
      );
      state.lastResolvedVideoUrl = url;
      return url;
    } catch (e) {
      state.hasParseError = true;
      rethrow;
    }
  }

  void cancelParsing() {
    _videoParsingService.cancelParsing();
  }

  bool playEpisode(VideoStateManager state, Episode episode) {
    if (episode.number == state.currentEpisode) {
      return false;
    }
    state.currentEpisode = episode.number;
    return true;
  }

  Episode? getNextEpisode(VideoStateManager state) {
    if (!state.hasNextEpisode) return null;
    return state.episodes.firstWhere(
      (e) => e.number == state.currentEpisode + 1,
      orElse: () => Episode(number: state.currentEpisode + 1),
    );
  }

  Episode? getPreviousEpisode(VideoStateManager state) {
    if (!state.hasPreviousEpisode) return null;
    return state.episodes.firstWhere(
      (e) => e.number == state.currentEpisode - 1,
      orElse: () => Episode(number: state.currentEpisode - 1),
    );
  }

  Future<VideoPageSourceSwitchResult> switchVideoSource({
    required VideoStateManager state,
    required VideoSource source,
    required String? animeTitle,
    required String? animeName,
    required int? bangumiId,
  }) async {
    state.currentPluginName = source.name;
    final episodes = await _episodeService.loadEpisodesWithVideoSource(
      source.name,
      animeTitle,
      animeName,
      bangumiId,
    );
    if (episodes.isNotEmpty) {
      state.episodes = episodes;
      return const VideoPageSourceSwitchResult(didLoadEpisodes: true);
    }
    return const VideoPageSourceSwitchResult(didLoadEpisodes: false);
  }

  void saveHistoryModel({
    required int? bangumiId,
    required String title,
    required String? animeTitle,
    required VideoStateManager state,
    required VideoPlaybackService playerController,
  }) {
    _historyService.saveHistoryModel(
      bangumiId: bangumiId,
      title: title,
      animeTitle: animeTitle,
      currentEpisode: state.currentEpisode,
      currentEpisodeTitle: state.currentEpisodeTitle,
      currentPluginName: state.currentPluginName,
      lastResolvedVideoUrl: state.lastResolvedVideoUrl,
      playerController: playerController,
    );
  }
}
