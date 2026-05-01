import 'package:flutter/foundation.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/settings/video_play/service/plugin_manager_service.dart';
import 'package:mikomi/features/video/controller/video_flow_controller.dart';
import 'package:mikomi/features/video/controller/video_system_ui_controller.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/state/video_page_state.dart';
import 'package:mikomi/features/video/ui/widgets/video_fit.dart';

class VideoPageFacade {
  final VideoPluginManager _pluginManager;
  final DanmakuSettingService _danmakuSettingService;
  final VideoSystemUiController _systemUiController;
  final List<VideoSource> _videoSources;

  late final VideoFlowController _flowController;
  late final ValueNotifier<VideoPageState> _stateNotifier;

  VideoPageFacade({
    required String title,
    required String videoUrl,
    required int currentEpisode,
    required List<Episode> episodes,
    required List<VideoSource>? videoSources,
    required String? sourceName,
    required Duration? initialProgress,
    required String? animeTitle,
    required String? animeName,
    required int? bangumiId,
    VideoPluginManager? pluginManager,
    DanmakuSettingService? danmakuSettingService,
    VideoSystemUiController? systemUiController,
  }) : _videoSources = videoSources ?? const [],
       _pluginManager = pluginManager ?? VideoPluginManager(),
       _danmakuSettingService =
           danmakuSettingService ?? DanmakuSettingService(),
       _systemUiController = systemUiController ?? VideoSystemUiController() {
    _flowController = VideoFlowController(
      title: title,
      videoUrl: videoUrl,
      currentEpisode: currentEpisode,
      episodes: episodes,
      sourceName: sourceName,
      initialProgress: initialProgress,
      animeTitle: animeTitle,
      animeName: animeName,
      bangumiId: bangumiId,
      onStateChanged: _syncState,
    );
    _stateNotifier = ValueNotifier(_flowController.pageState);
  }

  bool get hasVideoSources => _videoSources.isNotEmpty;
  List<VideoSource> get videoSources => List.unmodifiable(_videoSources);
  ValueListenable<VideoPageState> get stateListenable => _stateNotifier;
  VideoPageState get state => _stateNotifier.value;

  Future<void> initializePage() async {
    _systemUiController.enterPage();
    await _flowController.initialize();
    await Future.wait([_loadDanmakuEnabled(), _pluginManager.init()]);
  }

  Future<void> setDanmakuEnabled(bool enabled) async {
    _flowController.setDanmakuEnabled(enabled);
    await _danmakuSettingService.setShowDanmaku(enabled);
  }

  Future<void> updateDanmakuConfig(DanmakuConfig config) async {
    await DanmakuSettingService.setFontSize(config.fontSize);
    await DanmakuSettingService.setOpacity(config.opacity);
    await DanmakuSettingService.setArea(config.area);
    await DanmakuSettingService.setDuration(config.duration);
    await DanmakuSettingService.setStrokeWidth(config.strokeWidth);
    await DanmakuSettingService.setShowTop(config.showTop);
    await DanmakuSettingService.setShowBottom(config.showBottom);
    await DanmakuSettingService.setShowScroll(config.showScroll);
    await _flowController.setDanmakuConfig(config);
  }

  Future<void> initializeSmallScreenPlayback(String videoUrl) {
    return _flowController.initializePlayer(videoUrl);
  }

  Future<void> retrySmallScreenPlayback() {
    return _flowController.retrySmallScreenPlayback();
  }

  void attachSmallScreenDanmakuController(dynamic controller) {
    _flowController.attachSmallScreenDanmakuController(controller);
  }

  void toggleSmallScreenPlayPause() {
    _flowController.togglePlayPause();
  }

  void seekSmallScreenTo(Duration position) {
    _flowController.seekTo(position);
  }

  void setPlaybackSpeed(double speed) {
    _flowController.setPlaybackSpeed(speed);
  }

  Future<void> updateFullscreenFitMode(VideoFitMode mode) {
    return _flowController.updateFullscreenFitMode(mode);
  }

  void attachFullscreenDanmakuController(dynamic controller) {
    _flowController.attachFullscreenDanmakuController(controller);
  }

  Future<void> switchVideoSource(VideoSource source) {
    return _flowController.switchVideoSource(source);
  }

  Future<void> playEpisode(Episode episode) {
    return _flowController.playEpisode(episode);
  }

  Future<void> playNextEpisode() {
    return _flowController.playNextEpisode();
  }

  Future<void> playPreviousEpisode() {
    return _flowController.playPreviousEpisode();
  }

  Future<void> retryResolveVideoUrl() {
    return _flowController.retryResolveVideoUrl();
  }

  void toggleEpisodeSort() {
    _flowController.toggleEpisodeSort();
  }

  void toggleEpisodeListExpanded() {
    _flowController.toggleEpisodeListExpanded();
  }

  void expandDanmakuInput() {
    _flowController.expandDanmakuInput();
  }

  void collapseDanmakuInput() {
    _flowController.collapseDanmakuInput();
  }

  void syncAfterReassemble() {
    _flowController.sync();
  }

  Future<void> handlePagePop() {
    return _flowController.disposePlaybackService();
  }

  Future<void> disposePage() async {
    _systemUiController.restorePage();
    await _flowController.dispose();
    _stateNotifier.dispose();
  }

  Future<void> _loadDanmakuEnabled() async {
    final enabled = await _danmakuSettingService.getShowDanmaku();
    if (_flowController.isDisposed) return;
    _flowController.setDanmakuEnabled(enabled);
  }

  void _syncState(VideoPageState state) {
    _stateNotifier.value = state;
  }
}

typedef VideoPageDanmakuConfig = DanmakuConfig;
