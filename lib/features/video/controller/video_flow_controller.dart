import 'dart:async';

import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/settings/video_play/service/play_setting_service.dart';
import 'package:flutter/foundation.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/controller/video_episode_controller.dart';
import 'package:mikomi/features/video/controller/video_history_controller.dart';
import 'package:mikomi/features/video/controller/video_resolve_controller.dart';
import 'package:mikomi/features/video/controller/video_source_controller.dart';
import 'package:mikomi/features/video/controller/danmaku_controller.dart'
    as app_danmaku;
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_episode_service.dart';
import 'package:mikomi/features/video/services/video_history_service.dart';
import 'package:mikomi/features/video/services/video_parsing_service.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/fullscreen_video_state.dart';
import 'package:mikomi/features/video/state/video_page_state.dart';
import 'package:mikomi/features/video/state/video_player_listener.dart';
import 'package:mikomi/features/video/state/video_state.dart';
import 'package:mikomi/features/video/ui/widgets/video_fit.dart';

class VideoFlowController {
  final VideoEpisodeController _episodeController;
  final VideoSourceController _sourceController;
  final VideoResolveController _resolveController;
  final VideoHistoryController _historyController;
  final VideoPlaybackService _playbackService;
  final app_danmaku.DanmakuController _danmakuController;
  final VideoPlayerListenerController _playerListenerController;
  final ValueNotifier<VideoPlayerSnapshot> _playerSnapshotNotifier;
  final PlaySettingsService _playSettingsService;
  final String title;
  final String? animeTitle;
  final int? bangumiId;
  final void Function(VideoPageState state)? onStateChanged;

  VideoState _state;
  SmallscreenPlaybackState _smallscreenState =
      const SmallscreenPlaybackState.initial();
  DanmakuConfig _danmakuConfig = const DanmakuConfig();
  VideoFitMode _fullscreenFitMode = VideoFitMode.contain;
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
    PlaySettingsService? playSettingsService,
  }) {
    final resolvedEpisodeService = episodeService ?? VideoEpisodeService();
    final resolvedParsingService = parsingService ?? VideoParsingService();
    final resolvedHistoryService = historyService ?? VideoHistoryService();
    final resolvedPlaybackService = playbackService ?? VideoPlaybackService();
    final resolvedPlaySettingsService =
        playSettingsService ?? PlaySettingsService();

    final episodeController = VideoEpisodeController(
      episodeService: resolvedEpisodeService,
      animeTitle: animeTitle,
      animeName: animeName,
      bangumiId: bangumiId,
    );
    final resolveController = VideoResolveController(
      parsingService: resolvedParsingService,
    );
    final danmakuController = app_danmaku.DanmakuController();
    late final VideoFlowController flowController;
    final playerSnapshotNotifier = ValueNotifier(VideoPlayerSnapshot.initial());
    final playerListenerController = VideoPlayerListenerController(
      onSnapshotChanged: (snapshot) {
        flowController.updateSmallScreenSnapshot(snapshot);
      },
      onPositionChanged: (position) {
        flowController.syncDanmakuPlaybackPosition(position);
      },
      onDurationChanged: (duration) {
        flowController.restoreInitialProgressIfNeeded(duration);
      },
      onAutoPlayNext: () {
        unawaited(flowController.playNextEpisode());
      },
    );

    flowController = VideoFlowController._(
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
      playSettingsService: resolvedPlaySettingsService,
      danmakuController: danmakuController,
      playerListenerController: playerListenerController,
      playerSnapshotNotifier: playerSnapshotNotifier,
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
    return flowController;
  }

  VideoFlowController._({
    required VideoEpisodeController episodeController,
    required VideoSourceController sourceController,
    required VideoResolveController resolveController,
    required VideoHistoryController historyController,
    required VideoPlaybackService playbackService,
    required PlaySettingsService playSettingsService,
    required app_danmaku.DanmakuController danmakuController,
    required VideoPlayerListenerController playerListenerController,
    required ValueNotifier<VideoPlayerSnapshot> playerSnapshotNotifier,
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
       _playSettingsService = playSettingsService,
       _danmakuController = danmakuController,
       _playerListenerController = playerListenerController,
       _playerSnapshotNotifier = playerSnapshotNotifier,
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
    smallscreen: _smallscreenState,
    danmakuController: _danmakuController,
    danmakuConfig: _danmakuConfig,
    fullscreenState: _buildFullscreenState(),
    playerSnapshotListenable: _playerSnapshotNotifier,
    fullscreenFitMode: _fullscreenFitMode,
  );

  Future<void> initialize() async {
    _sync();
    _initializeVideoState();
    _startTimers();
    await _loadDanmakuConfig();
    await _loadFullscreenFitMode();
  }

  Future<void> initializePlayer(String videoUrl) async {
    if (videoUrl.isEmpty) return;
    _setSmallScreenState(
      _smallscreenState.copyWith(isLoading: true, errorMessage: null),
    );

    try {
      await _playbackService.initialize(smallScreen: true);
      await _playbackService.play(videoUrl);
      _playerListenerController.bind(
        _playbackService.player,
        hasNextEpisode: _state.hasNextEpisode,
      );
      _setSmallScreenState(
        _smallscreenState.copyWith(
          videoController: _playbackService.videoController,
          isInitialized: _playbackService.isInitialized,
          isLoading: false,
          errorMessage: null,
        ),
      );
      await loadDanmakuIfNeeded();
    } catch (error) {
      _setSmallScreenState(
        _smallscreenState.copyWith(
          isLoading: false,
          errorMessage: '视频加载失败: $error',
        ),
      );
    }
  }

  Future<void> retrySmallScreenPlayback() {
    return initializePlayer(_state.playerState.resolvedVideoUrl);
  }

  void updateSmallScreenSnapshot(VideoPlayerSnapshot snapshot) {
    _playerSnapshotNotifier.value = snapshot;
    _setSmallScreenState(
      _smallscreenState.copyWith(
        isBuffering: snapshot.isBuffering,
        isPlaying: snapshot.isPlaying,
        position: snapshot.position,
        duration: snapshot.duration,
      ),
    );
  }

  void syncDanmakuPlaybackPosition(Duration position) {
    _danmakuController.syncPlaybackPosition(
      isDanmakuEnabled: _state.isDanmakuEnabled,
      isPlaying: _smallscreenState.isPlaying,
      position: position,
    );
  }

  void restoreInitialProgressIfNeeded(Duration duration) {
    final progress = _initialProgress;
    final player = _playbackService.player;
    if (progress == null ||
        progress.inSeconds <= 0 ||
        duration.inSeconds <= 0 ||
        player == null ||
        progress.inSeconds >= duration.inSeconds) {
      return;
    }

    _initialProgress = null;
    Future.delayed(const Duration(milliseconds: 500), () {
      final currentPlayer = _playbackService.player;
      if (_isDisposed ||
          currentPlayer == null ||
          currentPlayer.state.duration.inSeconds <= 0 ||
          progress.inSeconds >= currentPlayer.state.duration.inSeconds) {
        return;
      }
      currentPlayer.seek(progress);
    });
  }

  Future<void> loadDanmakuIfNeeded() async {
    final int episode = _resolveDanmakuEpisodeNumber();
    await _danmakuController.loadDanmaku(
      isDanmakuEnabled: _state.isDanmakuEnabled,
      episode: episode,
      displayedEpisode: _state.currentEpisodeNumber,
      bangumiId: bangumiId,
      animeTitle: animeTitle,
    );
  }

  void attachSmallScreenDanmakuController(dynamic controller) {
    _danmakuController.attachCanvasController(controller);
  }

  void togglePlayPause() {
    final player = _playbackService.player;
    if (player == null) return;
    if (_smallscreenState.isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  void seekTo(Duration position) {
    _playbackService.player?.seek(position);
  }

  void setPlaybackSpeed(double speed) {
    _playbackService.player?.setRate(speed);
  }

  Future<void> updateFullscreenFitMode(VideoFitMode mode) async {
    _fullscreenFitMode = mode;
    _sync();
    await _playSettingsService.setVideoFitMode(mode);
  }

  void attachFullscreenDanmakuController(dynamic controller) {
    _danmakuController.attachCanvasController(controller);
  }

  Future<void> setDanmakuConfig(DanmakuConfig config) async {
    _danmakuConfig = config;
    _danmakuController.requestCurrentWindowRefresh();
    _sync();
  }

  void setDanmakuEnabled(bool enabled) {
    _setState(_state.setDanmakuEnabled(enabled));
    if (enabled) {
      unawaited(loadDanmakuIfNeeded());
    }
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
    if (nextState.playerState.resolvedVideoUrl.isNotEmpty) {
      await initializePlayer(nextState.playerState.resolvedVideoUrl);
    }
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
    _playerListenerController.dispose();
    _playerSnapshotNotifier.dispose();
    _danmakuController.dispose();
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

  Future<void> _loadDanmakuConfig() async {
    _danmakuConfig = await DanmakuSettingService.loadAll();
    _danmakuController.requestCurrentWindowRefresh();
    _sync();
  }

  Future<void> _loadFullscreenFitMode() async {
    _fullscreenFitMode = await _playSettingsService.getVideoFitMode();
    _sync();
  }

  int _resolveDanmakuEpisodeNumber() {
    final seasonEpisodeOffset = _state.episodes.isNotEmpty
        ? _state.episodes.first.number - 1
        : 0;
    final resolvedEpisodeNumber =
        _state.currentEpisodeNumber + seasonEpisodeOffset;
    return resolvedEpisodeNumber > 0
        ? resolvedEpisodeNumber
        : _state.currentEpisodeNumber;
  }

  FullscreenVideoState _buildFullscreenState() {
    return FullscreenVideoState(
      currentEpisode: _state.currentEpisodeNumber,
      episodes: _state.episodes,
      isLoadingEpisodes: _state.isEpisodeListLoading,
      isDescending: _state.isEpisodeSortDescending,
      hasNextEpisode: _state.hasNextEpisode,
      hasPreviousEpisode: _state.hasPreviousEpisode,
      currentSmallTitle: _state.currentEpisode?.smallTitle,
      isDanmakuEnabled: _state.isDanmakuEnabled,
      danmakuController: _danmakuController,
      danmakuFacade: _danmakuController.danmakuFacade,
      playerSnapshotListenable: _playerSnapshotNotifier,
    );
  }

  void _setSmallScreenState(SmallscreenPlaybackState state) {
    if (_isDisposed) return;
    _smallscreenState = state;
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
