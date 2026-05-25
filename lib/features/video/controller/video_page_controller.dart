import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/settings/video_play/service/play_setting_service.dart';
import 'package:mikomi/features/video/controller/video_episode_controller.dart';
import 'package:mikomi/features/video/controller/video_history_controller.dart';
import 'package:mikomi/features/video/controller/video_resolve_controller.dart';
import 'package:mikomi/features/video/controller/video_source_controller.dart';
import 'package:mikomi/features/video/controller/video_system_ui_controller.dart';
import 'package:mikomi/features/video/controller/danmaku_controller.dart'
    as app_danmaku;
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/danmaku_settings_coordinator.dart';
import 'package:mikomi/features/video/services/video_episode_service.dart';
import 'package:mikomi/features/video/services/video_history_service.dart';
import 'package:mikomi/features/video/services/video_parsing_service.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/fullscreen_video_state.dart';
import 'package:mikomi/features/video/state/video_page_state.dart';
import 'package:mikomi/features/video/state/video_player_listener.dart';
import 'package:mikomi/features/video/state/video_state.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/video/ui/widgets/video_fit.dart';

/// 视频播放页面唯一的状态编排器。
///
/// 替代旧架构中的 [VideoPageFacade] + [VideoFlowController] 双层结构。
/// 设计原则：
/// - 所有依赖通过构造函数显式注入（可测试性）
/// - 单一 [ValueNotifier<VideoPageState>] 驱动 UI
/// - 子控制器（episode / resolve / history / danmaku）负责各自的领域逻辑
/// - 本控制器只负责编排和状态流转
class VideoPageController {
  // ── 公开状态 ──

  late final ValueNotifier<VideoPageState> stateNotifier;
  VideoPageState get state => stateNotifier.value;
  ValueListenable<VideoPageState> get stateListenable => stateNotifier;

  /// 可切换的视频源列表（来自动漫详情页）
  final List<VideoSource> videoSources;
  bool get hasVideoSources => videoSources.isNotEmpty;

  // ── 内部依赖 ──

  final VideoSystemUiController _systemUi;
  final VideoEpisodeController _episodeCtrl;
  late final VideoSourceController _sourceCtrl;
  final VideoResolveController _resolveCtrl;
  late final VideoHistoryController _historyCtrl;
  final VideoPlaybackService _playback;
  final app_danmaku.DanmakuController _danmakuCtrl;
  late final VideoPlayerListenerController _playerListenerCtrl;
  final ValueNotifier<VideoPlayerSnapshot> _playerSnapshotNotifier;
  final DanmakuSettingsCoordinator _danmakuSettings;
  final PlaySettingsService _playSettings;
  final String _title;
  final String? _animeTitle;
  final int? _bangumiId;

  // ── 可变状态 ──

  VideoState _videoState;
  SmallscreenPlaybackState _smallscreenState =
      const SmallscreenPlaybackState.initial();
  DanmakuConfig _danmakuConfig = const DanmakuConfig();
  VideoFitMode _fullscreenFitMode = VideoFitMode.contain;
  Duration? _initialProgress;
  Timer? _timeoutTimer;
  bool _isDisposed = false;
  bool _didDisposePlayback = false;

  // ── 构造器 ──

  VideoPageController({
    required String title,
    required String videoUrl,
    required int currentEpisode,
    required List<Episode> episodes,
    required String? sourceName,
    required Duration? initialProgress,
    required String? animeTitle,
    required String? animeName,
    required int? bangumiId,
    VideoEpisodeService? episodeService,
    VideoParsingService? parsingService,
    VideoHistoryService? historyService,
    VideoPlaybackService? playbackService,
    PlaySettingsService? playSettingsService,
    DanmakuSettingsCoordinator? danmakuSettings,
    VideoSystemUiController? systemUi,
    this.videoSources = const [],
  }) :
       _title = title,
       _animeTitle = animeTitle,
       _bangumiId = bangumiId,
       _initialProgress = initialProgress,
       _systemUi = systemUi ?? VideoSystemUiController(),
       _playback = playbackService ?? VideoPlaybackService(),
       _playSettings = playSettingsService ?? PlaySettingsService(),
       _danmakuSettings = danmakuSettings ?? DanmakuSettingsCoordinator(),
       _danmakuCtrl = app_danmaku.DanmakuController(),
       _playerSnapshotNotifier = ValueNotifier(VideoPlayerSnapshot.initial()),
       _episodeCtrl = VideoEpisodeController(
         episodeService: episodeService ?? VideoEpisodeService(),
         animeTitle: animeTitle,
         animeName: animeName,
         bangumiId: bangumiId,
       ),
       _resolveCtrl = VideoResolveController(
         parsingService: parsingService ?? VideoParsingService(),
       ),
       _videoState = VideoState(
         currentEpisodeNumber: currentEpisode,
         episodes: episodes,
         currentVideoPageUrl: videoUrl,
         currentSourceName: sourceName,
       ) {
    // constructor body
    _sourceCtrl = VideoSourceController(
      episodeController: _episodeCtrl,
      resolveController: _resolveCtrl,
      playbackService: _playback,
    );
    _historyCtrl = VideoHistoryController(
      historyService: historyService ?? VideoHistoryService(),
      playbackService: _playback,
      title: title,
      animeTitle: animeTitle,
      bangumiId: bangumiId,
    );
    // 安全：回调仅被存储，在构造完成后才被异步触发
    _playerListenerCtrl = VideoPlayerListenerController(
      playSettingsService: _playSettings,
      onSnapshotChanged: _onPlayerSnapshot,
      onPositionChanged: _onPlayerPosition,
      onDurationChanged: _onPlayerDuration,
      onAutoPlayNext: _onAutoPlayNext,
    );
    stateNotifier = ValueNotifier(_buildPageState());
  }

  // ── 公开方法（action） ──

  bool get isDisposed => _isDisposed;

  Future<void> initialize() async {
    _systemUi.enterPage();
    _initializeVideoState();
    _startTimers();
    _danmakuConfig = await _danmakuSettings.loadConfig();
    _danmakuCtrl.applyConfig(_danmakuConfig);
    _fullscreenFitMode = await _playSettings.getVideoFitMode();
    _syncState();

    final enabled = await _danmakuSettings.getEnabled();
    if (!_isDisposed) setDanmakuEnabled(enabled);
  }

  // ── 弹幕 ──

  Future<void> setDanmakuEnabled(bool enabled) async {
    if (_videoState.isDanmakuEnabled == enabled) return;
    _setVideoState(_videoState.setDanmakuEnabled(enabled));
    await _danmakuSettings.setEnabled(enabled);
    if (enabled) {
      _danmakuCtrl.applyConfig(_danmakuConfig);
      unawaited(_loadDanmakuIfNeeded());
      _danmakuCtrl.requestCurrentWindowRefresh();
    } else {
      _danmakuCtrl.clearScreen();
    }
  }

  Future<void> updateDanmakuConfig(DanmakuConfig config) async {
    _danmakuConfig = config;
    _danmakuCtrl.applyConfig(config);
    _syncState();
    await _danmakuSettings.saveConfig(config);
  }

  void attachSmallScreenDanmakuController(dynamic ctrl) =>
      _danmakuCtrl.attachCanvasController(ctrl);

  void detachDanmakuController(dynamic ctrl) =>
      _danmakuCtrl.detachCanvasController(ctrl);

  void attachFullscreenDanmakuController(dynamic ctrl) =>
      _danmakuCtrl.attachCanvasController(ctrl);

  void expandDanmakuInput() =>
      _setVideoState(_videoState.expandDanmakuInput());

  void collapseDanmakuInput() =>
      _setVideoState(_videoState.collapseDanmakuInput());

  // ── 播放控制 ──

  Future<void> initializeSmallScreenPlayback(String videoUrl) async {
    if (videoUrl.isEmpty) return;
    _setSmallscreenState(
      _smallscreenState.copyWith(isLoading: true, errorMessage: null),
    );
    try {
      await _playback.initialize(smallScreen: true);
      await _playback.play(videoUrl);
      _playerListenerCtrl.bind(
        _playback.player,
        hasNextEpisode: _videoState.hasNextEpisode,
      );
      _setSmallscreenState(
        _smallscreenState.copyWith(
          videoController: _playback.videoController,
          isInitialized: _playback.isInitialized,
          isLoading: false,
          errorMessage: null,
        ),
      );
      await _loadDanmakuIfNeeded();
    } catch (error) {
      _setSmallscreenState(
        _smallscreenState.copyWith(
          isLoading: false,
          errorMessage: '视频加载失败: $error',
        ),
      );
    }
  }

  Future<void> retrySmallScreenPlayback() {
    return initializeSmallScreenPlayback(
      _videoState.playerState.resolvedVideoUrl,
    );
  }

  void togglePlayPause() {
    final player = _playback.player;
    if (player == null) return;
    if (_smallscreenState.isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  void seekTo(Duration position) => _playback.player?.seek(position);

  void setPlaybackSpeed(double speed) => _playback.player?.setRate(speed);

  // ── 全屏 ──

  Future<void> updateFullscreenFitMode(VideoFitMode mode) async {
    _fullscreenFitMode = mode;
    _syncState();
    await _playSettings.setVideoFitMode(mode);
  }

  // ── 视频源 ──

  Future<void> switchVideoSource(VideoSource source) async {
    _setVideoState(
      _videoState.copyWith(
        currentSourceName: source.name,
        isEpisodeListLoading: true,
        playbackPhase: const VideoPlaybackLoading(),
        showTimeoutNotice: false,
      ),
    );
    _clearInitialProgress();
    try {
      final nextState = await _sourceCtrl.switchSource(
        state: _videoState,
        source: source,
        isDisposed: () => _isDisposed,
      );
      if (nextState == null) return;
      _setVideoState(nextState);
      await retryResolveVideoUrl();
    } finally {
      if (!_isDisposed) {
        _setVideoState(_videoState.finishEpisodeLoading());
      }
    }
  }

  // ── 剧集 ──

  Future<void> playEpisode(Episode episode) async {
    final nextState = _episodeCtrl.selectEpisode(_videoState, episode);
    if (identical(nextState, _videoState)) return;
    _historyCtrl.save(_videoState);
    await _playback.stop();
    if (_isDisposed) return;
    _setVideoState(nextState);
    _clearInitialProgress();
    await retryResolveVideoUrl();
  }

  Future<void> playNextEpisode() async {
    final episode = _episodeCtrl.getNextEpisode(_videoState);
    if (episode != null) await playEpisode(episode);
  }

  Future<void> playPreviousEpisode() async {
    final episode = _episodeCtrl.getPreviousEpisode(_videoState);
    if (episode != null) await playEpisode(episode);
  }

  Future<void> retryResolveVideoUrl() async {
    _setVideoState(_videoState.startVideoResolving());
    _restartTimeoutTimer();
    final nextState = await _resolveCtrl.resolve(
      state: _videoState,
      isDisposed: () => _isDisposed,
    );
    _setVideoState(nextState);
    if (nextState.playerState.resolvedVideoUrl.isNotEmpty) {
      await initializeSmallScreenPlayback(
        nextState.playerState.resolvedVideoUrl,
      );
    }
  }

  void toggleEpisodeSort() =>
      _setVideoState(_episodeCtrl.toggleSort(_videoState));

  void toggleEpisodeListExpanded() =>
      _setVideoState(_episodeCtrl.toggleExpanded(_videoState));

  // ── 生命周期 ──

  void syncAfterReassemble() => _syncState();

  Future<void> handlePagePop() => _disposePlayback();

  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;
    _systemUi.restorePage();
    _episodeCtrl.cancelPendingRequests();
    _resolveCtrl.cancelPendingRequests();
    _timeoutTimer?.cancel();
    _historyCtrl.stop();
    _historyCtrl.save(_videoState);
    await _disposePlayback();
    _playerListenerCtrl.dispose();
    _playerSnapshotNotifier.dispose();
    _danmakuCtrl.dispose();
    _historyCtrl.dispose();
    stateNotifier.dispose();
  }

  // ── 内部方法 ──

  Future<void> _disposePlayback() async {
    if (_didDisposePlayback) return;
    _didDisposePlayback = true;
    await _playback.dispose();
  }

  void _setVideoState(VideoState next) {
    if (_isDisposed) return;
    _videoState = next;
    _syncState();
  }

  void _setSmallscreenState(SmallscreenPlaybackState next) {
    if (_isDisposed) return;
    _smallscreenState = next;
    _syncState();
  }

  void _syncState() {
    if (_isDisposed) return;
    stateNotifier.value = _buildPageState();
  }

  VideoPageState _buildPageState() {
    return VideoPageState(
      title: _title,
      animeTitle: _animeTitle,
      bangumiId: _bangumiId,
      playbackService: _playback,
      player: _videoState.playerState,
      episode: _videoState.episodeState,
      danmaku: _videoState.danmakuState,
      source: _videoState.sourceState,
      initialProgress: _initialProgress,
      smallscreen: _smallscreenState,
      danmakuController: _danmakuCtrl,
      danmakuConfig: _danmakuConfig,
      fullscreenState: _buildFullscreenState(),
      playerSnapshotListenable: _playerSnapshotNotifier,
      fullscreenFitMode: _fullscreenFitMode,
    );
  }

  FullscreenVideoState _buildFullscreenState() {
    return FullscreenVideoState(
      currentEpisode: _videoState.currentEpisodeNumber,
      episodes: _videoState.episodes,
      isLoadingEpisodes: _videoState.isEpisodeListLoading,
      isDescending: _videoState.isEpisodeSortDescending,
      hasNextEpisode: _videoState.hasNextEpisode,
      hasPreviousEpisode: _videoState.hasPreviousEpisode,
      currentSmallTitle: _videoState.currentEpisode?.smallTitle,
      isDanmakuEnabled: _videoState.isDanmakuEnabled,
      danmakuController: _danmakuCtrl,
      danmakuFacade: _danmakuCtrl.danmakuFacade,
      playerSnapshotListenable: _playerSnapshotNotifier,
    );
  }

  // ── 播放器回调 ──

  void _onPlayerSnapshot(VideoPlayerSnapshot snapshot) {
    _playerSnapshotNotifier.value = snapshot;
    final needsSync = _smallscreenState.isBuffering != snapshot.isBuffering ||
        _smallscreenState.isPlaying != snapshot.isPlaying ||
        _smallscreenState.duration != snapshot.duration;
    _smallscreenState = _smallscreenState.copyWith(
      isBuffering: snapshot.isBuffering,
      isPlaying: snapshot.isPlaying,
      position: snapshot.position,
      duration: snapshot.duration,
    );
    if (needsSync) _syncState();
  }

  void _onPlayerPosition(Duration position) {
    _danmakuCtrl.syncPlaybackPosition(
      isDanmakuEnabled: _videoState.isDanmakuEnabled,
      isPlaying: _smallscreenState.isPlaying,
      position: position,
    );
  }

  void _onPlayerDuration(Duration duration) {
    final progress = _initialProgress;
    final player = _playback.player;
    if (progress == null ||
        progress.inSeconds <= 0 ||
        duration.inSeconds <= 0 ||
        player == null ||
        progress.inSeconds >= duration.inSeconds) {
      return;
    }
    _initialProgress = null;
    Future.delayed(const Duration(milliseconds: 500), () {
      final p = _playback.player;
      if (_isDisposed || p == null) {
        return;
      }
      if (p.state.duration.inSeconds <= 0) {
        return;
      }
      if (progress.inSeconds >= p.state.duration.inSeconds) return;
      p.seek(progress);
    });
    _syncState();
  }

  void _onAutoPlayNext() => unawaited(playNextEpisode());

  // ── 弹幕加载 ──

  Future<void> _loadDanmakuIfNeeded() async {
    final seasonOffset = _videoState.episodes.isNotEmpty
        ? _videoState.episodes.first.number - 1
        : 0;
    final resolvedEpisode =
        _videoState.currentEpisodeNumber + seasonOffset;
    await _danmakuCtrl.loadDanmaku(
      isDanmakuEnabled: _videoState.isDanmakuEnabled,
      episode: resolvedEpisode > 0
          ? resolvedEpisode
          : _videoState.currentEpisodeNumber,
      displayedEpisode: _videoState.currentEpisodeNumber,
      bangumiId: _bangumiId,
      animeTitle: _animeTitle,
    );
  }

  // ── 初始化与定时器 ──

  void _initializeVideoState() {
    final shouldLoadEpisodes =
        _videoState.episodes.isEmpty && _videoState.currentSourceName != null;

    if (_videoState.episodes.isEmpty &&
        _videoState.currentSourceName != null &&
        _animeTitle != null) {
      if (_videoState.currentVideoPageUrl.isNotEmpty) {
        if (_resolveCtrl.isDirectStreamUrl(
          _videoState.currentVideoPageUrl,
        )) {
          _setVideoState(_videoState.markUseCachedResolvedUrl());
        } else {
          _setVideoState(_videoState.setInitialResolving());
        }
      } else {
        _setVideoState(_videoState.markWaitForEpisodeResolve());
      }
    } else {
      _setVideoState(_videoState.setInitialResolving());
    }

    if (shouldLoadEpisodes) {
      unawaited(_loadEpisodesIfNeeded());
    } else if (_videoState.playerState.isResolvingVideo) {
      unawaited(retryResolveVideoUrl());
    }
  }

  Future<void> _loadEpisodesIfNeeded() async {
    if (_videoState.episodes.isNotEmpty ||
        _videoState.currentSourceName == null) {
      return;
    }

    _setVideoState(_videoState.startEpisodeLoading());
    try {
      final result = await _episodeCtrl.loadEpisodesIfNeeded(
        state: _videoState,
        isDisposed: () => _isDisposed,
      );
      if (result == null) return;
      _setVideoState(result.state);
      if (result.shouldSilentRefresh) {
        await _refreshResolvedUrlSilently();
      } else if (result.shouldResolve) {
        await retryResolveVideoUrl();
      }
    } finally {
      if (!_isDisposed) {
        _setVideoState(_videoState.finishEpisodeLoading());
      }
    }
  }

  Future<void> _refreshResolvedUrlSilently() async {
    final nextState = await _resolveCtrl.refreshSilently(
      state: _videoState,
      isDisposed: () => _isDisposed,
    );
    if (nextState == null) return;
    _setVideoState(nextState);
  }

  void _startTimers() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (_isDisposed) return;
      _setVideoState(_videoState.showTimeout());
    });
    _historyCtrl.start(getState: () => _videoState);
  }

  void _restartTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (_isDisposed) return;
      _setVideoState(_videoState.showTimeout());
    });
  }

  void _clearInitialProgress() {
    _initialProgress = null;
    _syncState();
  }
}
