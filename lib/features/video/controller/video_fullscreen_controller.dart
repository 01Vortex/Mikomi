import 'package:canvas_danmaku/canvas_danmaku.dart' as canvas;
import 'package:flutter/foundation.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/settings/video_play/service/play_setting_service.dart';
import 'package:mikomi/features/video/controller/danmaku_controller.dart'
    as app_danmaku;
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/fullscreen_page_state.dart';
import 'package:mikomi/features/video/state/fullscreen_video_state.dart';
import 'package:mikomi/features/video/ui/widgets/video_fit.dart';

class VideoFullscreenController {
  final VideoPlaybackService _playbackService;
  final PlaySettingsService _playSettingsService;
  final DanmakuSettingService _danmakuSettingService;
  final ValueNotifier<FullscreenVideoState> _sourceStateNotifier;
  final void Function(FullscreenPageState state)? onStateChanged;

  late FullscreenPageState _state;
  canvas.DanmakuController<dynamic>? _fullscreenCanvasController;

  VideoFullscreenController({
    required VideoPlaybackService playbackService,
    required ValueNotifier<FullscreenVideoState> sourceStateNotifier,
    PlaySettingsService? playSettingsService,
    DanmakuSettingService? danmakuSettingService,
    this.onStateChanged,
  }) : _playbackService = playbackService,
       _sourceStateNotifier = sourceStateNotifier,
       _playSettingsService = playSettingsService ?? PlaySettingsService(),
       _danmakuSettingService =
           danmakuSettingService ?? DanmakuSettingService() {
    final videoState = _sourceStateNotifier.value;
    final danmakuController =
        videoState.danmakuController ?? app_danmaku.DanmakuController();
    _state = FullscreenPageState(
      videoState: videoState,
      videoController: _playbackService.videoController,
      danmakuController: danmakuController,
      danmakuConfig: const DanmakuConfig(),
      fitMode: VideoFitMode.contain,
      isVideoReady: _playbackService.videoController != null,
    );
  }

  FullscreenPageState get state => _state;

  Future<void> initialize() async {
    _sourceStateNotifier.addListener(_syncFromSourceState);
    await Future.wait([loadFitMode(), loadDanmakuConfig()]);
    _sync();
  }

  Future<void> loadFitMode() async {
    final mode = await _playSettingsService.getVideoFitMode();
    _setState(_state.copyWith(fitMode: mode));
  }

  Future<void> loadDanmakuConfig() async {
    final config = await DanmakuSettingService.loadAll();
    _setState(_state.copyWith(danmakuConfig: config));
    _state.danmakuController.requestCurrentWindowRefresh();
  }

  void registerFullscreenController(
    canvas.DanmakuController<dynamic> controller,
  ) {
    _fullscreenCanvasController = controller;
    _state.danmakuController.attachCanvasController(controller);
  }

  Future<void> updateFitMode(VideoFitMode mode) async {
    _setState(_state.copyWith(fitMode: mode));
    await _playSettingsService.setVideoFitMode(mode);
  }

  Future<void> setDanmakuEnabled(bool enabled) async {
    await _danmakuSettingService.setShowDanmaku(enabled);
    final nextVideoState = _state.videoState.copyWith(
      isDanmakuEnabled: enabled,
    );
    _sourceStateNotifier.value = nextVideoState;
    _setState(
      _state.copyWith(
        videoState: nextVideoState,
        isDanmakuInputVisible: enabled,
      ),
    );
    _state.danmakuController.requestCurrentWindowRefresh();
  }

  void setDanmakuInputVisible(bool visible) {
    _setState(_state.copyWith(isDanmakuInputVisible: visible));
  }

  Future<void> updateDanmakuConfig(DanmakuConfig config) async {
    await Future.wait([
      DanmakuSettingService.setFontSize(config.fontSize),
      DanmakuSettingService.setOpacity(config.opacity),
      DanmakuSettingService.setArea(config.area),
      DanmakuSettingService.setDuration(config.duration),
      DanmakuSettingService.setStrokeWidth(config.strokeWidth),
      DanmakuSettingService.setShowTop(config.showTop),
      DanmakuSettingService.setShowBottom(config.showBottom),
      DanmakuSettingService.setShowScroll(config.showScroll),
    ]);
    _setState(_state.copyWith(danmakuConfig: config));
    _state.danmakuController.requestCurrentWindowRefresh();
  }

  void togglePlayPause() {
    _playbackService.player?.playOrPause();
  }

  void seekTo(Duration position) {
    _playbackService.player?.seek(position);
  }

  void setPlaybackSpeed(double speed) {
    _playbackService.player?.setRate(speed);
  }

  void dispose() {
    if (_fullscreenCanvasController != null) {
      _state.danmakuController.detachCanvasController(
        _fullscreenCanvasController!,
      );
      _fullscreenCanvasController = null;
    }
    _sourceStateNotifier.removeListener(_syncFromSourceState);
  }

  void _syncFromSourceState() {
    _setState(
      _state.copyWith(
        videoState: _sourceStateNotifier.value,
        videoController: _playbackService.videoController,
        isVideoReady: _playbackService.videoController != null,
      ),
    );
  }

  void _setState(FullscreenPageState state) {
    _state = state;
    _sync();
  }

  void _sync() {
    onStateChanged?.call(_state);
  }
}
