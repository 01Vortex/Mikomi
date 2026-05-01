import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/config/app_theme.dart';
import 'package:mikomi/features/video/controller/video_fullscreen_controller.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/fullscreen_page_state.dart';
import 'package:mikomi/features/video/ui/widgets/smallscreen/smallscreen_video.dart';
import 'package:mikomi/features/video/ui/widgets/video_fit.dart';

class FullscreenPageFacade {
  final VideoPlaybackService playbackService;
  final String title;
  final ValueNotifier<FullscreenVideoState> _sourceStateNotifier;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final ValueChanged<Episode>? onEpisodeSelected;
  final VoidCallback? onToggleSort;

  late final VideoFullscreenController _controller;
  late final ValueNotifier<FullscreenPageState> _stateNotifier;

  FullscreenPageFacade({
    required this.playbackService,
    required this.title,
    required ValueNotifier<FullscreenVideoState> stateNotifier,
    this.onNextEpisode,
    this.onPreviousEpisode,
    this.onEpisodeSelected,
    this.onToggleSort,
  }) : _sourceStateNotifier = stateNotifier {
    _controller = VideoFullscreenController(
      playbackService: playbackService,
      sourceStateNotifier: _sourceStateNotifier,
      onStateChanged: _syncState,
    );
    _stateNotifier = ValueNotifier(_controller.state);
  }

  ValueListenable<FullscreenPageState> get stateListenable => _stateNotifier;
  FullscreenPageState get state => _stateNotifier.value;

  Future<void> initializePage() async {
    _enterFullscreen();
    await _controller.initialize();
  }

  void registerFullscreenController(dynamic controller) {
    _controller.registerFullscreenController(controller);
  }

  Future<void> updateFitMode(VideoFitMode mode) {
    return _controller.updateFitMode(mode);
  }

  Future<void> setDanmakuEnabled(bool enabled) {
    return _controller.setDanmakuEnabled(enabled);
  }

  void handlePagePop() {
    _exitFullscreen();
  }

  void disposePage() {
    _controller.dispose();
    _exitFullscreen();
    _stateNotifier.dispose();
  }

  void _syncState(FullscreenPageState state) {
    _stateNotifier.value = state;
  }

  void _enterFullscreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _exitFullscreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
}
