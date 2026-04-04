import 'package:mikomi/features/video/models/episode_model.dart';

sealed class VideoPlaybackPhase {
  const VideoPlaybackPhase();
}

class VideoPlaybackIdle extends VideoPlaybackPhase {
  const VideoPlaybackIdle();
}

class VideoPlaybackLoading extends VideoPlaybackPhase {
  const VideoPlaybackLoading();
}

class VideoPlaybackReady extends VideoPlaybackPhase {
  final String url;

  const VideoPlaybackReady(this.url);
}

class VideoPlaybackError extends VideoPlaybackPhase {
  final Object? error;

  const VideoPlaybackError([this.error]);
}

class VideoPlayerViewState {
  final int currentEpisodeNumber;
  final int totalEpisodes;
  final String? currentSmallTitle;
  final List<Episode> episodes;
  final bool isEpisodeListLoading;
  final bool isEpisodeSortDescending;
  final bool isDanmakuEnabled;
  final bool hasNextEpisode;
  final bool hasPreviousEpisode;
  final VideoPlaybackPhase playbackPhase;
  final bool showTimeoutNotice;

  const VideoPlayerViewState({
    required this.currentEpisodeNumber,
    required this.totalEpisodes,
    required this.currentSmallTitle,
    required this.episodes,
    required this.isEpisodeListLoading,
    required this.isEpisodeSortDescending,
    required this.isDanmakuEnabled,
    required this.hasNextEpisode,
    required this.hasPreviousEpisode,
    required this.playbackPhase,
    required this.showTimeoutNotice,
  });

  bool get hasPlaybackError => playbackPhase is VideoPlaybackError;
  bool get isResolvingVideo => playbackPhase is VideoPlaybackLoading;
  String get resolvedVideoUrl => switch (playbackPhase) {
    VideoPlaybackReady(:final url) => url,
    _ => '',
  };
}

class VideoEpisodeViewState {
  final bool isLoading;
  final List<Episode> episodes;
  final bool isDescending;
  final bool isExpanded;
  final int currentEpisodeNumber;

  const VideoEpisodeViewState({
    required this.isLoading,
    required this.episodes,
    required this.isDescending,
    required this.isExpanded,
    required this.currentEpisodeNumber,
  });
}

class VideoDanmakuViewState {
  final bool isDanmakuEnabled;
  final bool isInputExpanded;

  const VideoDanmakuViewState({
    required this.isDanmakuEnabled,
    required this.isInputExpanded,
  });
}

class VideoSourceViewState {
  final String? currentSourceName;

  const VideoSourceViewState({required this.currentSourceName});
}

class VideoStateManager {
  final int currentEpisodeNumber;
  final List<Episode> episodes;
  final String currentVideoPageUrl;
  final String? currentSourceName;
  final bool isEpisodeSortDescending;
  final bool isDanmakuEnabled;
  final bool isDanmakuInputExpanded;
  final bool isEpisodeListExpanded;
  final bool showTimeoutNotice;
  final bool isEpisodeListLoading;
  final bool isUsingCachedResolvedUrl;
  final String lastResolvedVideoUrl;
  final bool shouldResolveAfterEpisodesLoaded;
  final VideoPlaybackPhase playbackPhase;

  const VideoStateManager({
    this.currentEpisodeNumber = 1,
    this.episodes = const [],
    this.currentVideoPageUrl = '',
    this.currentSourceName,
    this.isEpisodeSortDescending = false,
    this.isDanmakuEnabled = false,
    this.isDanmakuInputExpanded = false,
    this.isEpisodeListExpanded = true,
    this.showTimeoutNotice = false,
    this.isEpisodeListLoading = false,
    this.isUsingCachedResolvedUrl = false,
    this.lastResolvedVideoUrl = '',
    this.shouldResolveAfterEpisodesLoaded = false,
    this.playbackPhase = const VideoPlaybackIdle(),
  });

  int get totalEpisodes => episodes.length;

  Episode? get currentEpisode {
    try {
      return episodes.firstWhere(
        (episode) => episode.number == currentEpisodeNumber,
      );
    } catch (_) {
      return null;
    }
  }

  String? get currentSmallTitle => currentEpisode?.smallTitle;

  bool get hasNextEpisode => currentEpisodeNumber < totalEpisodes;
  bool get hasPreviousEpisode => currentEpisodeNumber > 1;

  List<Episode> get sortedEpisodes =>
      isEpisodeSortDescending ? episodes.reversed.toList() : episodes;

  VideoPlayerViewState get playerViewState => VideoPlayerViewState(
    currentEpisodeNumber: currentEpisodeNumber,
    totalEpisodes: totalEpisodes,
    currentSmallTitle: currentSmallTitle,
    episodes: episodes,
    isEpisodeListLoading: isEpisodeListLoading,
    isEpisodeSortDescending: isEpisodeSortDescending,
    isDanmakuEnabled: isDanmakuEnabled,
    hasNextEpisode: hasNextEpisode,
    hasPreviousEpisode: hasPreviousEpisode,
    playbackPhase: playbackPhase,
    showTimeoutNotice: showTimeoutNotice,
  );

  VideoEpisodeViewState get episodeViewState => VideoEpisodeViewState(
    isLoading: isEpisodeListLoading,
    episodes: episodes,
    isDescending: isEpisodeSortDescending,
    isExpanded: isEpisodeListExpanded,
    currentEpisodeNumber: currentEpisodeNumber,
  );

  VideoDanmakuViewState get danmakuViewState => VideoDanmakuViewState(
    isDanmakuEnabled: isDanmakuEnabled,
    isInputExpanded: isDanmakuInputExpanded,
  );

  VideoSourceViewState get sourceViewState =>
      VideoSourceViewState(currentSourceName: currentSourceName);

  VideoStateManager copyWith({
    int? currentEpisodeNumber,
    List<Episode>? episodes,
    String? currentVideoPageUrl,
    Object? currentSourceName = _sentinel,
    bool? isEpisodeSortDescending,
    bool? isDanmakuEnabled,
    bool? isDanmakuInputExpanded,
    bool? isEpisodeListExpanded,
    bool? showTimeoutNotice,
    bool? isEpisodeListLoading,
    bool? isUsingCachedResolvedUrl,
    String? lastResolvedVideoUrl,
    bool? shouldResolveAfterEpisodesLoaded,
    VideoPlaybackPhase? playbackPhase,
  }) {
    return VideoStateManager(
      currentEpisodeNumber: currentEpisodeNumber ?? this.currentEpisodeNumber,
      episodes: episodes ?? this.episodes,
      currentVideoPageUrl: currentVideoPageUrl ?? this.currentVideoPageUrl,
      currentSourceName: currentSourceName == _sentinel
          ? this.currentSourceName
          : currentSourceName as String?,
      isEpisodeSortDescending:
          isEpisodeSortDescending ?? this.isEpisodeSortDescending,
      isDanmakuEnabled: isDanmakuEnabled ?? this.isDanmakuEnabled,
      isDanmakuInputExpanded:
          isDanmakuInputExpanded ?? this.isDanmakuInputExpanded,
      isEpisodeListExpanded:
          isEpisodeListExpanded ?? this.isEpisodeListExpanded,
      showTimeoutNotice: showTimeoutNotice ?? this.showTimeoutNotice,
      isEpisodeListLoading: isEpisodeListLoading ?? this.isEpisodeListLoading,
      isUsingCachedResolvedUrl:
          isUsingCachedResolvedUrl ?? this.isUsingCachedResolvedUrl,
      lastResolvedVideoUrl: lastResolvedVideoUrl ?? this.lastResolvedVideoUrl,
      shouldResolveAfterEpisodesLoaded:
          shouldResolveAfterEpisodesLoaded ??
          this.shouldResolveAfterEpisodesLoaded,
      playbackPhase: playbackPhase ?? this.playbackPhase,
    );
  }

  VideoStateManager setDanmakuEnabled(bool enabled) {
    return copyWith(
      isDanmakuEnabled: enabled,
      isDanmakuInputExpanded: enabled ? isDanmakuInputExpanded : false,
    );
  }

  VideoStateManager expandDanmakuInput() {
    return copyWith(isDanmakuInputExpanded: true);
  }

  VideoStateManager collapseDanmakuInput() {
    return copyWith(isDanmakuInputExpanded: false);
  }

  VideoStateManager toggleEpisodeSort() {
    return copyWith(isEpisodeSortDescending: !isEpisodeSortDescending);
  }

  VideoStateManager toggleEpisodeListExpanded() {
    return copyWith(isEpisodeListExpanded: !isEpisodeListExpanded);
  }

  VideoStateManager startEpisodeLoading() {
    return copyWith(isEpisodeListLoading: true);
  }

  VideoStateManager finishEpisodeLoading() {
    return copyWith(isEpisodeListLoading: false);
  }

  VideoStateManager startVideoResolving() {
    return copyWith(
      showTimeoutNotice: false,
      playbackPhase: const VideoPlaybackLoading(),
    );
  }

  VideoStateManager showTimeout() {
    return copyWith(showTimeoutNotice: true);
  }

  VideoStateManager applyResolvedVideoUrl(String resolvedUrl) {
    return copyWith(
      lastResolvedVideoUrl: resolvedUrl,
      playbackPhase: resolvedUrl.isEmpty
          ? const VideoPlaybackIdle()
          : VideoPlaybackReady(resolvedUrl),
    );
  }

  VideoStateManager applyResolveError(Object error) {
    return copyWith(playbackPhase: VideoPlaybackError(error));
  }

  VideoStateManager markUseCachedResolvedUrl() {
    return copyWith(
      isUsingCachedResolvedUrl: true,
      shouldResolveAfterEpisodesLoaded: true,
      lastResolvedVideoUrl: currentVideoPageUrl,
      playbackPhase: VideoPlaybackReady(currentVideoPageUrl),
    );
  }

  VideoStateManager markWaitForEpisodeResolve() {
    return copyWith(
      shouldResolveAfterEpisodesLoaded: true,
      playbackPhase: const VideoPlaybackIdle(),
    );
  }

  VideoStateManager setInitialResolving() {
    return copyWith(playbackPhase: const VideoPlaybackLoading());
  }

  VideoStateManager withEpisodes(List<Episode> nextEpisodes) {
    final nextEpisodeNumber =
        currentEpisodeNumber > nextEpisodes.length ? 1 : currentEpisodeNumber;
    return copyWith(
      episodes: nextEpisodes,
      currentEpisodeNumber: nextEpisodeNumber,
    );
  }

  VideoStateManager clearEpisodeResolveFlag() {
    return copyWith(
      shouldResolveAfterEpisodesLoaded: false,
      isUsingCachedResolvedUrl: false,
    );
  }

  VideoStateManager selectEpisode(Episode episode) {
    if (episode.number == currentEpisodeNumber) {
      return this;
    }
    return copyWith(
      currentEpisodeNumber: episode.number,
      currentVideoPageUrl: episode.url ?? currentVideoPageUrl,
      playbackPhase: const VideoPlaybackLoading(),
      showTimeoutNotice: false,
    );
  }

  VideoStateManager switchSource({
    required String sourceName,
    required List<Episode> nextEpisodes,
  }) {
    return copyWith(
      currentSourceName: sourceName,
      episodes: nextEpisodes.isNotEmpty ? nextEpisodes : episodes,
      isEpisodeListLoading: true,
      playbackPhase: const VideoPlaybackLoading(),
      showTimeoutNotice: false,
    );
  }

  Episode? getNextEpisode() {
    if (!hasNextEpisode) {
      return null;
    }
    return episodes.firstWhere(
      (episode) => episode.number == currentEpisodeNumber + 1,
      orElse: () => Episode(number: currentEpisodeNumber + 1),
    );
  }

  Episode? getPreviousEpisode() {
    if (!hasPreviousEpisode) {
      return null;
    }
    return episodes.firstWhere(
      (episode) => episode.number == currentEpisodeNumber - 1,
      orElse: () => Episode(number: currentEpisodeNumber - 1),
    );
  }

  static const Object _sentinel = Object();
}
