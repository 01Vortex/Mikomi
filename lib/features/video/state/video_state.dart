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

class VideoPlayerState {
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

  const VideoPlayerState({
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

class VideoEpisodeState {
  final bool isLoading;
  final List<Episode> episodes;
  final bool isDescending;
  final bool isExpanded;
  final int currentEpisodeNumber;

  const VideoEpisodeState({
    required this.isLoading,
    required this.episodes,
    required this.isDescending,
    required this.isExpanded,
    required this.currentEpisodeNumber,
  });
}

class VideoDanmakuState {
  final bool isDanmakuEnabled;
  final bool isInputExpanded;

  const VideoDanmakuState({
    required this.isDanmakuEnabled,
    required this.isInputExpanded,
  });
}

class VideoSourceState {
  final String? currentSourceName;

  const VideoSourceState({required this.currentSourceName});
}

class VideoState {
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

  const VideoState({
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

  VideoPlayerState get playerState => VideoPlayerState(
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

  VideoEpisodeState get episodeState => VideoEpisodeState(
    isLoading: isEpisodeListLoading,
    episodes: episodes,
    isDescending: isEpisodeSortDescending,
    isExpanded: isEpisodeListExpanded,
    currentEpisodeNumber: currentEpisodeNumber,
  );

  VideoDanmakuState get danmakuState => VideoDanmakuState(
    isDanmakuEnabled: isDanmakuEnabled,
    isInputExpanded: isDanmakuInputExpanded,
  );

  VideoSourceState get sourceState =>
      VideoSourceState(currentSourceName: currentSourceName);

  VideoState copyWith({
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
    return VideoState(
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

  VideoState setDanmakuEnabled(bool enabled) {
    return copyWith(
      isDanmakuEnabled: enabled,
      isDanmakuInputExpanded: enabled ? isDanmakuInputExpanded : false,
    );
  }

  VideoState expandDanmakuInput() {
    return copyWith(isDanmakuInputExpanded: true);
  }

  VideoState collapseDanmakuInput() {
    return copyWith(isDanmakuInputExpanded: false);
  }

  VideoState toggleEpisodeSort() {
    return copyWith(isEpisodeSortDescending: !isEpisodeSortDescending);
  }

  VideoState toggleEpisodeListExpanded() {
    return copyWith(isEpisodeListExpanded: !isEpisodeListExpanded);
  }

  VideoState startEpisodeLoading() {
    return copyWith(isEpisodeListLoading: true);
  }

  VideoState finishEpisodeLoading() {
    return copyWith(isEpisodeListLoading: false);
  }

  VideoState startVideoResolving() {
    return copyWith(
      showTimeoutNotice: false,
      playbackPhase: const VideoPlaybackLoading(),
    );
  }

  VideoState showTimeout() {
    return copyWith(showTimeoutNotice: true);
  }

  VideoState applyResolvedVideoUrl(String resolvedUrl) {
    return copyWith(
      lastResolvedVideoUrl: resolvedUrl,
      playbackPhase: resolvedUrl.isEmpty
          ? const VideoPlaybackIdle()
          : VideoPlaybackReady(resolvedUrl),
    );
  }

  VideoState applyResolveError(Object error) {
    return copyWith(playbackPhase: VideoPlaybackError(error));
  }

  VideoState markUseCachedResolvedUrl() {
    return copyWith(
      isUsingCachedResolvedUrl: true,
      shouldResolveAfterEpisodesLoaded: true,
      lastResolvedVideoUrl: currentVideoPageUrl,
      playbackPhase: VideoPlaybackReady(currentVideoPageUrl),
    );
  }

  VideoState markWaitForEpisodeResolve() {
    return copyWith(
      shouldResolveAfterEpisodesLoaded: true,
      playbackPhase: const VideoPlaybackIdle(),
    );
  }

  VideoState setInitialResolving() {
    return copyWith(playbackPhase: const VideoPlaybackLoading());
  }

  VideoState withEpisodes(List<Episode> nextEpisodes) {
    final nextEpisodeNumber =
        currentEpisodeNumber > nextEpisodes.length ? 1 : currentEpisodeNumber;
    return copyWith(
      episodes: nextEpisodes,
      currentEpisodeNumber: nextEpisodeNumber,
    );
  }

  VideoState clearEpisodeResolveFlag() {
    return copyWith(
      shouldResolveAfterEpisodesLoaded: false,
      isUsingCachedResolvedUrl: false,
    );
  }

  VideoState selectEpisode(Episode episode) {
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

  VideoState switchSource({
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
