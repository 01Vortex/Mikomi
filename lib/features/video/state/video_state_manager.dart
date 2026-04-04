import 'package:mikomi/features/video/models/episode_model.dart';

sealed class VideoPlaybackStatus {
  const VideoPlaybackStatus();
}

class VideoPlaybackIdle extends VideoPlaybackStatus {
  const VideoPlaybackIdle();
}

class VideoPlaybackLoading extends VideoPlaybackStatus {
  const VideoPlaybackLoading();
}

class VideoPlaybackReady extends VideoPlaybackStatus {
  final String url;

  const VideoPlaybackReady(this.url);
}

class VideoPlaybackError extends VideoPlaybackStatus {
  final Object? error;

  const VideoPlaybackError([this.error]);
}

class VideoStateManager {
  final int currentEpisode;
  final List<Episode> episodes;
  final String videoUrl;
  final String? currentPluginName;
  final bool isDescending;
  final bool isDanmakuEnabled;
  final bool isDanmakuInputExpanded;
  final bool isEpisodesExpanded;
  final bool showTimeoutHint;
  final bool isLoadingEpisodes;
  final bool isUsingCachedPlayUrl;
  final String lastResolvedVideoUrl;
  final bool isReassembling;
  final bool shouldParseAfterEpisodesLoaded;
  final VideoPlaybackStatus playbackStatus;

  const VideoStateManager({
    this.currentEpisode = 1,
    this.episodes = const [],
    this.videoUrl = '',
    this.currentPluginName,
    this.isDescending = false,
    this.isDanmakuEnabled = false,
    this.isDanmakuInputExpanded = false,
    this.isEpisodesExpanded = true,
    this.showTimeoutHint = false,
    this.isLoadingEpisodes = false,
    this.isUsingCachedPlayUrl = false,
    this.lastResolvedVideoUrl = '',
    this.isReassembling = false,
    this.shouldParseAfterEpisodesLoaded = false,
    this.playbackStatus = const VideoPlaybackIdle(),
  });

  int get totalEpisodes => episodes.length;

  String? get currentEpisodeTitle {
    try {
      return episodes.firstWhere((ep) => ep.number == currentEpisode).title;
    } catch (_) {
      return null;
    }
  }

  bool get hasNextEpisode => currentEpisode < totalEpisodes;
  bool get hasPreviousEpisode => currentEpisode > 1;

  List<Episode> get sortedEpisodes =>
      isDescending ? episodes.reversed.toList() : episodes;

  bool get hasParseError => playbackStatus is VideoPlaybackError;
  bool get isResolvingVideo => playbackStatus is VideoPlaybackLoading;
  String get resolvedVideoUrl => switch (playbackStatus) {
    VideoPlaybackReady(:final url) => url,
    _ => '',
  };

  VideoStateManager copyWith({
    int? currentEpisode,
    List<Episode>? episodes,
    String? videoUrl,
    Object? currentPluginName = _sentinel,
    bool? isDescending,
    bool? isDanmakuEnabled,
    bool? isDanmakuInputExpanded,
    bool? isEpisodesExpanded,
    bool? showTimeoutHint,
    bool? isLoadingEpisodes,
    bool? isUsingCachedPlayUrl,
    String? lastResolvedVideoUrl,
    bool? isReassembling,
    bool? shouldParseAfterEpisodesLoaded,
    VideoPlaybackStatus? playbackStatus,
  }) {
    return VideoStateManager(
      currentEpisode: currentEpisode ?? this.currentEpisode,
      episodes: episodes ?? this.episodes,
      videoUrl: videoUrl ?? this.videoUrl,
      currentPluginName: currentPluginName == _sentinel
          ? this.currentPluginName
          : currentPluginName as String?,
      isDescending: isDescending ?? this.isDescending,
      isDanmakuEnabled: isDanmakuEnabled ?? this.isDanmakuEnabled,
      isDanmakuInputExpanded:
          isDanmakuInputExpanded ?? this.isDanmakuInputExpanded,
      isEpisodesExpanded: isEpisodesExpanded ?? this.isEpisodesExpanded,
      showTimeoutHint: showTimeoutHint ?? this.showTimeoutHint,
      isLoadingEpisodes: isLoadingEpisodes ?? this.isLoadingEpisodes,
      isUsingCachedPlayUrl: isUsingCachedPlayUrl ?? this.isUsingCachedPlayUrl,
      lastResolvedVideoUrl: lastResolvedVideoUrl ?? this.lastResolvedVideoUrl,
      isReassembling: isReassembling ?? this.isReassembling,
      shouldParseAfterEpisodesLoaded:
          shouldParseAfterEpisodesLoaded ?? this.shouldParseAfterEpisodesLoaded,
      playbackStatus: playbackStatus ?? this.playbackStatus,
    );
  }

  static const Object _sentinel = Object();
}
