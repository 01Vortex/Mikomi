import 'dart:async';

import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/controller/video_episode_controller.dart';
import 'package:mikomi/features/video/controller/video_history_controller.dart';
import 'package:mikomi/features/video/controller/video_resolve_controller.dart';
import 'package:mikomi/features/video/controller/video_source_controller.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_episode_service.dart';
import 'package:mikomi/features/video/services/video_history_service.dart';
import 'package:mikomi/features/video/services/video_parsing_service.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/video_page_state.dart';
import 'package:mikomi/features/video/state/video_state.dart';

class VideoFlowController {
  final VideoEpisodeController _episodeController;
  final VideoSourceController _sourceController;
  final VideoResolveController _resolveController;
  final VideoHistoryController _historyController;
  final VideoPlaybackService _playbackService;
  final String title;
  final String? animeTitle;
  final int? bangumiId;
  final void Function(VideoPageState state)? onStateChanged;

  VideoState _state;
  Duration? _initialProgress;
  Timer? _timeoutTimer;
  bool _isDisposed = false;
  bool _didDisposePlaybackService = false;

  factory VideoFlowController({
    required String title,
    required String videoUrl,
    required int currentEpisode,
    required List<Episode> episodes,
    required String? sourceName,
    required Duration? initialProgress,
    required String? animeTitle,
    required String? animeName,
    required int? bangumiId,
    void Function(VideoPageState state)? onStateChanged,
    VideoEpisodeService? episodeService,
    VideoParsingService? parsingService,
    VideoHistoryService? historyService,
    VideoPlaybackService? playbackService,
  }) {
    final resolvedEpisodeService = episodeService ?? VideoEpisodeService();
    final resolvedParsingService = parsingService ?? VideoParsingService();
    final resolvedHistoryService = historyService ?? VideoHistoryService();
    final resolvedPlaybackService = playbackService ?? VideoPlaybackService();

    final episodeController = VideoEpisodeController(
      episodeService: resolvedEpisodeService,
      animeTitle: animeTitle,
      animeName: animeName,
      bangumiId: bangumiId,
    );
    final resolveController = VideoResolveController(
      parsingService: resolvedParsingService,
    );

    return VideoFlowController._(
      episodeController: episodeController,
      sourceController: VideoSourceController(
        episodeController: episodeController,
        resolveController: resolveController,
        playbackService: resolvedPlaybackService,
      ),
      resolveController: resolveController,
      historyController: VideoHistoryController(
        historyService: resolvedHistoryService,
        playbackService: resolvedPlaybackService,
        title: title,
        animeTitle: animeTitle,
        bangumiId: bangumiId,
      ),
      playbackService: resolvedPlaybackService,
      title: title,
      videoUrl: videoUrl,
      currentEpisode: currentEpisode,
      episodes: episodes,
      sourceName: sourceName,
      initialProgress: initialProgress,
      animeTitle: animeTitle,
      bangumiId: bangumiId,
      onStateChanged: onStateChanged,
    );
  }

  VideoFlowController._({
    required VideoEpisodeController episodeController,
    required VideoSourceController sourceController,
    required VideoResolveController resolveController,
    required VideoHistoryController historyController,
    required VideoPlaybackService playbackService,
    required this.title,
    required String videoUrl,
    required int currentEpisode,
    required List<Episode> episodes,
    required String? sourceName,
    required Duration? initialProgress,
    required this.animeTitle,
    required this.bangumiId,
    this.onStateChanged,
  }) : _episodeController = episodeController,
       _sourceController = sourceController,
       _resolveController = resolveController,
       _historyController = historyController,
       _playbackService = playbackService,
       _initialProgress = initialProgress,
       _state = VideoState(
         currentEpisodeNumber: currentEpisode,
         episodes: episodes,
         currentVideoPageUrl: videoUrl,
         currentSourceName: sourceName,
       );

  bool get isDisposed => _isDisposed;
  VideoState get videoState => _state;
  VideoPageState get pageState => VideoPageState(
    title: title,
    animeTitle: animeTitle,
    bangumiId: bangumiId,
    playbackService: _playbackService,
    player: _state.playerState,
    episode: _state.episodeState,
    danmaku: _state.danmakuState,
    source: _state.sourceState,
    initialProgress: _initialProgress,
  );

  Future<void> initialize() async {
    _sync();
    _initializeVideoState();
    _startTimers();
  }

  void setDanmakuEnabled(bool enabled) {
    _setState(_state.setDanmakuEnabled(enabled));
  }

  Future<void> switchVideoSource(VideoSource source) async {
    _setState(
      _state.copyWith(
        currentSourceName: source.name,
        isEpisodeListLoading: true,
        playbackPhase: const VideoPlaybackLoading(),
        showTimeoutNotice: false,
      ),
    );
    _clearInitialProgress();

    try {
      final nextState = await _sourceController.switchSource(
        state: _state,
        source: source,
        isDisposed: () => _isDisposed,
      );

      if (nextState == null) return;
      _setState(nextState);
      await retryResolveVideoUrl();
    } finally {
      if (!_isDisposed) {
        _setState(_state.finishEpisodeLoading());
      }
    }
  }

  Future<void> playEpisode(Episode episode) async {
    final nextState = _episodeController.selectEpisode(_state, episode);
    if (identical(nextState, _state)) return;

    saveHistory();
    await _playbackService.stop();
    if (_isDisposed) return;

    _setState(nextState);
    _clearInitialProgress();
    await retryResolveVideoUrl();
  }

  Future<void> playNextEpisode() async {
    final episode = _episodeController.getNextEpisode(_state);
    if (episode == null) return;
    await playEpisode(episode);
  }

  Future<void> playPreviousEpisode() async {
    final episode = _episodeController.getPreviousEpisode(_state);
    if (episode == null) return;
    await playEpisode(episode);
  }

  Future<void> retryResolveVideoUrl() async {
    _setState(_state.startVideoResolving());
    _restartTimeoutTimer();
    final nextState = await _resolveController.resolve(
      state: _state,
      isDisposed: () => _isDisposed,
    );
    _setState(nextState);
  }

  void toggleEpisodeSort() {
    _setState(_episodeController.toggleSort(_state));
  }

  void toggleEpisodeListExpanded() {
    _setState(_episodeController.toggleExpanded(_state));
  }

  void expandDanmakuInput() {
    _setState(_state.expandDanmakuInput());
  }

  void collapseDanmakuInput() {
    _setState(_state.collapseDanmakuInput());
  }

  void sync() {
    _sync();
  }

  void saveHistory() {
    _historyController.save(_state);
  }

  Future<void> disposePlaybackService() async {
    if (_didDisposePlaybackService) return;
    _didDisposePlaybackService = true;
    await _playbackService.dispose();
  }

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _episodeController.cancelPendingRequests();
    _resolveController.cancelPendingRequests();
    _timeoutTimer?.cancel();
    _historyController.stop();
    saveHistory();
    await disposePlaybackService();
    _historyController.dispose();
  }

  Future<void> _loadEpisodesIfNeeded() async {
    if (_state.episodes.isNotEmpty || _state.currentSourceName == null) {
      return;
    }

    _setState(_state.startEpisodeLoading());
    try {
      final result = await _episodeController.loadEpisodesIfNeeded(
        state: _state,
        isDisposed: () => _isDisposed,
      );

      if (result == null) return;
      _setState(result.state);

      if (result.shouldSilentRefresh) {
        await _refreshResolvedVideoUrlSilently();
      } else if (result.shouldResolve) {
        await retryResolveVideoUrl();
      }
    } finally {
      if (!_isDisposed) {
        _setState(_state.finishEpisodeLoading());
      }
    }
  }

  Future<void> _refreshResolvedVideoUrlSilently() async {
    final nextState = await _resolveController.refreshSilently(
      state: _state,
      isDisposed: () => _isDisposed,
    );
    if (nextState == null) return;
    _setState(nextState);
  }

  void _initializeVideoState() {
    final shouldLoadEpisodes =
        _state.episodes.isEmpty && _state.currentSourceName != null;

    if (_state.episodes.isEmpty &&
        _state.currentSourceName != null &&
        animeTitle != null) {
      if (_state.currentVideoPageUrl.isNotEmpty) {
        if (_resolveController.isDirectStreamUrl(_state.currentVideoPageUrl)) {
          _setState(_state.markUseCachedResolvedUrl());
        } else {
          _setState(_state.setInitialResolving());
        }
      } else {
        _setState(_state.markWaitForEpisodeResolve());
      }
    } else {
      _setState(_state.setInitialResolving());
    }

    if (shouldLoadEpisodes) {
      unawaited(_loadEpisodesIfNeeded());
    } else if (_state.playerState.isResolvingVideo) {
      unawaited(retryResolveVideoUrl());
    }
  }

  void _startTimers() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (_isDisposed) return;
      _setState(_state.showTimeout());
    });
    _historyController.start(getState: () => _state);
  }

  void _restartTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (_isDisposed) return;
      _setState(_state.showTimeout());
    });
  }

  void _clearInitialProgress() {
    _initialProgress = null;
    _sync();
  }

  void _setState(VideoState nextState) {
    if (_isDisposed) return;
    _state = nextState;
    _sync();
  }

  void _sync() {
    if (_isDisposed) return;
    onStateChanged?.call(pageState);
  }
}
