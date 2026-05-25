import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_episode_service.dart';
import 'package:mikomi/features/video/state/video_state.dart';

class VideoEpisodeController {
  final VideoEpisodeService _episodeService;
  final String? animeTitle;
  final String? animeName;
  final int? bangumiId;

  int _requestToken = 0;

  VideoEpisodeController({
    required VideoEpisodeService episodeService,
    required this.animeTitle,
    required this.animeName,
    required this.bangumiId,
  }) : _episodeService = episodeService;

  int get requestToken => _requestToken;

  Future<List<Episode>> loadEpisodes(String sourceName) {
    return _episodeService.loadEpisodes(
      sourceName: sourceName,
      animeTitle: animeTitle,
      animeName: animeName,
      bangumiId: bangumiId,
    );
  }

  Future<VideoEpisodeLoadResult?> loadEpisodesIfNeeded({
    required VideoState state,
    required bool Function() isDisposed,
  }) async {
    if (state.episodes.isNotEmpty || state.currentSourceName == null) {
      return null;
    }

    final token = ++_requestToken;
    final episodes = await loadEpisodes(state.currentSourceName!);
    if (!_canApply(token, isDisposed) || episodes.isEmpty) {
      return null;
    }

    final nextState = state.withEpisodes(episodes).clearEpisodeResolveFlag();
    return VideoEpisodeLoadResult(
      state: nextState,
      shouldResolve:
          state.shouldResolveAfterEpisodesLoaded &&
          !state.isUsingCachedResolvedUrl,
      shouldSilentRefresh:
          state.shouldResolveAfterEpisodesLoaded &&
          state.isUsingCachedResolvedUrl,
    );
  }

  void cancelPendingRequests() {
    _requestToken++;
  }

  bool canApplyResult(int token, bool Function() isDisposed) {
    return _canApply(token, isDisposed);
  }

  bool _canApply(int token, bool Function() isDisposed) {
    return !isDisposed() && token == _requestToken;
  }
}

class VideoEpisodeLoadResult {
  final VideoState state;
  final bool shouldResolve;
  final bool shouldSilentRefresh;

  const VideoEpisodeLoadResult({
    required this.state,
    required this.shouldResolve,
    required this.shouldSilentRefresh,
  });
}
