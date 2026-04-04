import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_episode_service.dart';
import 'package:mikomi/features/video/services/video_history_service.dart';
import 'package:mikomi/features/video/services/video_parsing_service.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/video_state_manager.dart';

class VideoController {
  final VideoEpisodeService _episodeService;
  final VideoParsingService _parsingService;
  final VideoHistoryService _historyService;
  final VideoPlaybackService playbackService;
  final String title;
  final String? animeTitle;
  final String? animeName;
  final int? bangumiId;

  VideoStateManager _state;
  Timer? _timeoutTimer;
  Timer? _saveHistoryTimer;
  int _episodeRequestToken = 0;
  int _silentRefreshToken = 0;
  int _resolveRequestToken = 0;
  bool _isDisposed = false;
  bool _didDisposePlaybackService = false;

  final ValueNotifier<VideoPlayerViewState> playerViewNotifier;
  final ValueNotifier<VideoEpisodeViewState> episodeViewNotifier;
  final ValueNotifier<VideoDanmakuViewState> danmakuViewNotifier;
  final ValueNotifier<VideoSourceViewState> sourceViewNotifier;
  final ValueNotifier<Duration?> initialProgressNotifier;

  factory VideoController({
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
  }) {
    final initialState = VideoStateManager(
      currentEpisodeNumber: currentEpisode,
      episodes: episodes,
      currentVideoPageUrl: videoUrl,
      currentSourceName: sourceName,
    );

    return VideoController._(
      title: title,
      animeTitle: animeTitle,
      animeName: animeName,
      bangumiId: bangumiId,
      episodeService: episodeService ?? VideoEpisodeService(),
      parsingService: parsingService ?? VideoParsingService(),
      historyService: historyService ?? VideoHistoryService(),
      playbackService: playbackService ?? VideoPlaybackService(),
      initialState: initialState,
      initialProgress: initialProgress,
    );
  }

  VideoController._({
    required this.title,
    required this.animeTitle,
    required this.animeName,
    required this.bangumiId,
    required VideoEpisodeService episodeService,
    required VideoParsingService parsingService,
    required VideoHistoryService historyService,
    required this.playbackService,
    required VideoStateManager initialState,
    required Duration? initialProgress,
  }) : _episodeService = episodeService,
       _parsingService = parsingService,
       _historyService = historyService,
       _state = initialState,
       playerViewNotifier = ValueNotifier(initialState.playerViewState),
       episodeViewNotifier = ValueNotifier(initialState.episodeViewState),
       danmakuViewNotifier = ValueNotifier(initialState.danmakuViewState),
       sourceViewNotifier = ValueNotifier(initialState.sourceViewState),
       initialProgressNotifier = ValueNotifier(initialProgress);

  bool get isDisposed => _isDisposed;

  void initialize() {
    _syncNotifiers();
    _initializeVideoState();
    _startTimers();
  }

  void _syncNotifiers() {
    if (_isDisposed) return;
    playerViewNotifier.value = _state.playerViewState;
    episodeViewNotifier.value = _state.episodeViewState;
    danmakuViewNotifier.value = _state.danmakuViewState;
    sourceViewNotifier.value = _state.sourceViewState;
  }

  void _setState(VideoStateManager nextState) {
    if (_isDisposed) return;
    _state = nextState;
    _syncNotifiers();
  }

  void _initializeVideoState() {
    final shouldLoadEpisodes =
        _state.episodes.isEmpty && _state.currentSourceName != null;

    if (_state.episodes.isEmpty &&
        _state.currentSourceName != null &&
        animeTitle != null) {
      if (_state.currentVideoPageUrl.isNotEmpty) {
        if (_parsingService.isDirectStreamUrl(_state.currentVideoPageUrl)) {
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
      unawaited(loadEpisodesIfNeeded());
    } else if (playerViewNotifier.value.isResolvingVideo) {
      unawaited(resolveCurrentVideoUrl());
    }
  }

  void _startTimers() {
    _timeoutTimer?.cancel();
    _saveHistoryTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (_isDisposed) return;
      _setState(_state.showTimeout());
    });
    _saveHistoryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      saveHistory();
    });
  }

  void _restartTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 3), () {
      if (_isDisposed) return;
      _setState(_state.showTimeout());
    });
  }

  Future<void> loadEpisodesIfNeeded() async {
    if (_state.episodes.isNotEmpty || _state.currentSourceName == null) {
      return;
    }

    final token = ++_episodeRequestToken;
    _setState(_state.startEpisodeLoading());
    try {
      final episodes = await _episodeService.loadEpisodes(
        sourceName: _state.currentSourceName!,
        animeTitle: animeTitle,
        animeName: animeName,
        bangumiId: bangumiId,
      );

      if (!_canApplyEpisodeResult(token) || episodes.isEmpty) {
        return;
      }

      final previousState = _state;
      var nextState = _state.withEpisodes(episodes);
      final shouldSilentRefresh =
          previousState.shouldResolveAfterEpisodesLoaded &&
          previousState.isUsingCachedResolvedUrl;
      final shouldResolve =
          previousState.shouldResolveAfterEpisodesLoaded &&
          !previousState.isUsingCachedResolvedUrl;

      nextState = nextState.clearEpisodeResolveFlag();
      _setState(nextState);

      if (shouldSilentRefresh) {
        await refreshResolvedVideoUrlSilently();
      } else if (shouldResolve) {
        await resolveCurrentVideoUrl();
      }
    } finally {
      if (_canApplyEpisodeResult(token)) {
        _setState(_state.finishEpisodeLoading());
      }
    }
  }

  Future<void> refreshResolvedVideoUrlSilently() async {
    if (_state.currentSourceName == null || _state.currentEpisode == null) {
      return;
    }

    final token = ++_silentRefreshToken;
    try {
      final pageUrl = _state.currentEpisode!.url ?? _state.currentVideoPageUrl;
      final resolvedUrl = await _parsingService.refreshParsedUrl(
        pageUrl,
        _state.currentSourceName!,
        _state.lastResolvedVideoUrl,
      );

      if (!_canApplySilentRefreshResult(token) ||
          resolvedUrl.isEmpty ||
          resolvedUrl == _state.lastResolvedVideoUrl) {
        return;
      }

      _setState(_state.applyResolvedVideoUrl(resolvedUrl));
    } catch (_) {}
  }

  Future<void> resolveCurrentVideoUrl() async {
    final token = ++_resolveRequestToken;
    _setState(_state.startVideoResolving());
    _restartTimeoutTimer();

    try {
      final resolvedUrl = await _parsingService.resolveVideoUrl(
        _state.currentVideoPageUrl,
        _state.currentSourceName,
        _state.episodes,
        _state.currentEpisodeNumber,
      );

      if (!_canApplyResolveResult(token)) {
        return;
      }

      _setState(_state.applyResolvedVideoUrl(resolvedUrl));
    } catch (error) {
      if (!_canApplyResolveResult(token)) {
        return;
      }
      _setState(_state.applyResolveError(error));
    }
  }

  Future<void> playEpisode(Episode episode) async {
    final nextState = _state.selectEpisode(episode);
    if (identical(nextState, _state)) {
      return;
    }

    saveHistory();
    await playbackService.stop();
    if (_isDisposed) {
      return;
    }

    _setState(nextState);
    initialProgressNotifier.value = null;
    await resolveCurrentVideoUrl();
  }

  Future<void> playNextEpisode() async {
    final episode = _state.getNextEpisode();
    if (episode == null) return;
    await playEpisode(episode);
  }

  Future<void> playPreviousEpisode() async {
    final episode = _state.getPreviousEpisode();
    if (episode == null) return;
    await playEpisode(episode);
  }

  Future<void> switchVideoSource(VideoSource source) async {
    _parsingService.cancelParsing();
    _setState(
      _state.copyWith(
        currentSourceName: source.name,
        isEpisodeListLoading: true,
        playbackPhase: const VideoPlaybackLoading(),
        showTimeoutNotice: false,
      ),
    );
    initialProgressNotifier.value = null;
    await playbackService.stop();

    try {
      final episodes = await _episodeService.loadEpisodes(
        sourceName: source.name,
        animeTitle: animeTitle,
        animeName: animeName,
        bangumiId: bangumiId,
      );

      if (_isDisposed) {
        return;
      }

      _setState(
        _state.switchSource(sourceName: source.name, nextEpisodes: episodes),
      );
      await resolveCurrentVideoUrl();
    } finally {
      if (!_isDisposed) {
        _setState(_state.finishEpisodeLoading());
      }
    }
  }

  void toggleEpisodeSort() {
    _setState(_state.toggleEpisodeSort());
  }

  void toggleEpisodeListExpanded() {
    _setState(_state.toggleEpisodeListExpanded());
  }

  void setDanmakuEnabled(bool enabled) {
    _setState(_state.setDanmakuEnabled(enabled));
  }

  void toggleDanmakuEnabled() {
    _setState(_state.setDanmakuEnabled(!_state.isDanmakuEnabled));
  }

  void expandDanmakuInput() {
    _setState(_state.expandDanmakuInput());
  }

  void collapseDanmakuInput() {
    _setState(_state.collapseDanmakuInput());
  }

  void syncAfterReassemble() {
    _syncNotifiers();
  }

  void saveHistory() {
    _historyService.saveHistory(
      bangumiId: bangumiId,
      title: title,
      animeTitle: animeTitle,
      currentEpisode: _state.currentEpisodeNumber,
      currentSmallTitle: _state.currentSmallTitle,
      currentSourceName: _state.currentSourceName,
      lastResolvedVideoUrl: _state.lastResolvedVideoUrl,
      playbackService: playbackService,
    );
  }

  Future<void> disposePlaybackService() async {
    if (_didDisposePlaybackService) {
      return;
    }
    _didDisposePlaybackService = true;
    try {
      await playbackService.dispose();
    } catch (_) {}
  }

  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    _episodeRequestToken++;
    _silentRefreshToken++;
    _resolveRequestToken++;
    _timeoutTimer?.cancel();
    _saveHistoryTimer?.cancel();
    saveHistory();
    await disposePlaybackService();
    playerViewNotifier.dispose();
    episodeViewNotifier.dispose();
    danmakuViewNotifier.dispose();
    sourceViewNotifier.dispose();
    initialProgressNotifier.dispose();
  }

  bool _canApplyEpisodeResult(int token) {
    return !_isDisposed && token == _episodeRequestToken;
  }

  bool _canApplySilentRefreshResult(int token) {
    return !_isDisposed && token == _silentRefreshToken;
  }

  bool _canApplyResolveResult(int token) {
    return !_isDisposed && token == _resolveRequestToken;
  }
}
