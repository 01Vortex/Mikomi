import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_episode_service.dart';
import 'package:mikomi/features/video/services/video_history_service.dart';
import 'package:mikomi/features/video/services/video_parsing_service.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/video_state_manager.dart';

class VideoPageInitializeResult {
  final VideoStateManager state;
  final bool shouldLoadEpisodes;

  const VideoPageInitializeResult({
    required this.state,
    required this.shouldLoadEpisodes,
  });
}

class VideoPageEpisodeLoadResult {
  final VideoStateManager state;
  final bool didLoadEpisodes;
  final bool shouldRefreshParsedUrlSilently;
  final bool shouldUpdateCurrentVideoUrl;

  const VideoPageEpisodeLoadResult({
    required this.state,
    required this.didLoadEpisodes,
    required this.shouldRefreshParsedUrlSilently,
    required this.shouldUpdateCurrentVideoUrl,
  });
}

class VideoPageSourceSwitchResult {
  final VideoStateManager state;
  final bool didLoadEpisodes;

  const VideoPageSourceSwitchResult({
    required this.state,
    required this.didLoadEpisodes,
  });
}

class VideoTimerHandles {
  final Timer timeoutTimer;
  final Timer saveHistoryTimer;

  const VideoTimerHandles({
    required this.timeoutTimer,
    required this.saveHistoryTimer,
  });
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

  VideoStateManager initializeState({
    required int currentEpisode,
    required List<Episode> episodes,
    required String videoUrl,
    required String? pluginName,
  }) {
    return VideoStateManager(
      currentEpisode: currentEpisode,
      episodes: episodes,
      videoUrl: videoUrl,
      currentPluginName: pluginName,
    );
  }

  VideoStateManager updateDanmakuEnabled(
    VideoStateManager state,
    bool enabled,
  ) {
    return state.copyWith(
      isDanmakuEnabled: enabled,
      isDanmakuInputExpanded: enabled ? state.isDanmakuInputExpanded : false,
    );
  }

  VideoStateManager expandDanmakuInput(VideoStateManager state) {
    return state.copyWith(isDanmakuInputExpanded: true);
  }

  VideoStateManager collapseDanmakuInput(VideoStateManager state) {
    return state.copyWith(isDanmakuInputExpanded: false);
  }

  VideoStateManager toggleEpisodeSort(VideoStateManager state) {
    return state.copyWith(isDescending: !state.isDescending);
  }

  VideoStateManager toggleEpisodeExpand(VideoStateManager state) {
    return state.copyWith(isEpisodesExpanded: !state.isEpisodesExpanded);
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
          final nextState = state.copyWith(
            isUsingCachedPlayUrl: true,
            shouldParseAfterEpisodesLoaded: true,
            lastResolvedVideoUrl: state.videoUrl,
            playbackStatus: VideoPlaybackReady(state.videoUrl),
          );
          return VideoPageInitializeResult(
            state: nextState,
            shouldLoadEpisodes: shouldLoadEpisodes,
          );
        }
        return VideoPageInitializeResult(
          state: state.copyWith(playbackStatus: const VideoPlaybackLoading()),
          shouldLoadEpisodes: shouldLoadEpisodes,
        );
      }

      return VideoPageInitializeResult(
        state: state.copyWith(
          shouldParseAfterEpisodesLoaded: true,
          playbackStatus: const VideoPlaybackIdle(),
        ),
        shouldLoadEpisodes: shouldLoadEpisodes,
      );
    }

    return VideoPageInitializeResult(
      state: state.copyWith(playbackStatus: const VideoPlaybackLoading()),
      shouldLoadEpisodes: shouldLoadEpisodes,
    );
  }

  VideoTimerHandles startTimers({
    required VoidCallback onTimeout,
    required VoidCallback onSaveHistory,
  }) {
    return VideoTimerHandles(
      timeoutTimer: Timer(const Duration(seconds: 3), onTimeout),
      saveHistoryTimer: Timer.periodic(
        const Duration(seconds: 10),
        (_) => onSaveHistory(),
      ),
    );
  }

  Timer restartTimeoutTimer({required VoidCallback onTimeout}) {
    return Timer(const Duration(seconds: 3), onTimeout);
  }

  VideoStateManager beginEpisodeLoading(VideoStateManager state) {
    return state.copyWith(isLoadingEpisodes: true);
  }

  VideoStateManager endEpisodeLoading(VideoStateManager state) {
    return state.copyWith(isLoadingEpisodes: false);
  }

  VideoStateManager showTimeoutHint(VideoStateManager state) {
    return state.copyWith(showTimeoutHint: true);
  }

  VideoStateManager resetResolveState(VideoStateManager state) {
    return state.copyWith(
      showTimeoutHint: false,
      playbackStatus: const VideoPlaybackLoading(),
    );
  }

  VideoStateManager beginSourceSwitch(VideoStateManager state) {
    cancelParsing();
    return state.copyWith(
      isLoadingEpisodes: true,
      playbackStatus: const VideoPlaybackLoading(),
    );
  }

  Future<VideoPageEpisodeLoadResult> loadEpisodesInBackground({
    required VideoStateManager state,
    required String? animeTitle,
    required String? animeName,
    required int? bangumiId,
  }) async {
    if (animeTitle == null || state.currentPluginName == null) {
      return VideoPageEpisodeLoadResult(
        state: state,
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
        return VideoPageEpisodeLoadResult(
          state: state,
          didLoadEpisodes: false,
          shouldRefreshParsedUrlSilently: false,
          shouldUpdateCurrentVideoUrl: false,
        );
      }

      var nextState = state.copyWith(
        episodes: episodes,
        currentEpisode: state.currentEpisode > episodes.length
            ? 1
            : state.currentEpisode,
      );

      final shouldRefreshParsedUrlSilently =
          nextState.shouldParseAfterEpisodesLoaded &&
          nextState.isUsingCachedPlayUrl;
      final shouldUpdateCurrentVideoUrl =
          nextState.shouldParseAfterEpisodesLoaded &&
          !nextState.isUsingCachedPlayUrl;

      nextState = nextState.copyWith(
        shouldParseAfterEpisodesLoaded: false,
        isUsingCachedPlayUrl: false,
      );

      return VideoPageEpisodeLoadResult(
        state: nextState,
        didLoadEpisodes: true,
        shouldRefreshParsedUrlSilently: shouldRefreshParsedUrlSilently,
        shouldUpdateCurrentVideoUrl: shouldUpdateCurrentVideoUrl,
      );
    } catch (e) {
      debugPrint('后台加载剧集失败: $e');
      return VideoPageEpisodeLoadResult(
        state: state,
        didLoadEpisodes: false,
        shouldRefreshParsedUrlSilently: false,
        shouldUpdateCurrentVideoUrl: false,
      );
    }
  }

  Future<VideoStateManager> refreshParsedUrlSilently(
    VideoStateManager state,
  ) async {
    if (state.currentPluginName == null || state.episodes.isEmpty) {
      return state;
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
      if (parsedUrl.isEmpty || parsedUrl == state.lastResolvedVideoUrl) {
        return state;
      }
      return state.copyWith(
        lastResolvedVideoUrl: parsedUrl,
        playbackStatus: VideoPlaybackReady(parsedUrl),
      );
    } catch (e) {
      debugPrint('静默刷新失败: $e');
      return state;
    }
  }

  Future<VideoStateManager> resolveCurrentVideoUrl(
    VideoStateManager state,
  ) async {
    try {
      final url = await _videoParsingService.resolveVideoUrl(
        state.videoUrl,
        state.currentPluginName,
        state.episodes,
        state.currentEpisode,
      );
      return state.copyWith(
        lastResolvedVideoUrl: url,
        playbackStatus: url.isEmpty
            ? const VideoPlaybackIdle()
            : VideoPlaybackReady(url),
      );
    } catch (e) {
      return state.copyWith(playbackStatus: VideoPlaybackError(e));
    }
  }

  void cancelParsing() {
    _videoParsingService.cancelParsing();
  }

  VideoStateManager? playEpisode(VideoStateManager state, Episode episode) {
    if (episode.number == state.currentEpisode) {
      return null;
    }
    return state.copyWith(
      currentEpisode: episode.number,
      playbackStatus: const VideoPlaybackLoading(),
      showTimeoutHint: false,
    );
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
    final episodes = await _episodeService.loadEpisodesWithVideoSource(
      source.name,
      animeTitle,
      animeName,
      bangumiId,
    );
    final nextState = state.copyWith(
      currentPluginName: source.name,
      episodes: episodes.isNotEmpty ? episodes : state.episodes,
    );
    return VideoPageSourceSwitchResult(
      state: nextState,
      didLoadEpisodes: episodes.isNotEmpty,
    );
  }

  VideoStateManager beginReassemble(VideoStateManager state) {
    if (state.isReassembling) {
      return state;
    }
    return state.copyWith(isReassembling: true);
  }

  VideoStateManager endReassemble(VideoStateManager state) {
    return state.copyWith(isReassembling: false);
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
