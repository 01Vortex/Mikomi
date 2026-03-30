import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/ui/widgets/fullscreen_video.dart';
import 'package:mikomi/features/video/ui/widgets/smallscreen_video.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';

class FullscreenVideoPage extends StatefulWidget {
  final VideoPlaybackService playerController;
  final String title;
  final ValueNotifier<FullscreenVideoState> stateNotifier;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final Function(Episode)? onEpisodeSelected;
  final VoidCallback? onToggleSort;

  const FullscreenVideoPage({
    super.key,
    required this.playerController,
    required this.title,
    required this.stateNotifier,
    this.onNextEpisode,
    this.onPreviousEpisode,
    this.onEpisodeSelected,
    this.onToggleSort,
  });

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  late FullscreenVideoState _state;
  DanmakuController? _fullscreenDanmakuController;

  @override
  void initState() {
    super.initState();
    _state = widget.stateNotifier.value;
    widget.stateNotifier.addListener(_onStateChanged);
    _enterFullscreen();
  }

  void _onStateChanged() {
    if (!mounted) return;
    final newState = widget.stateNotifier.value;
    // broadcaster 更新时重新注册
    if (newState.danmakuBroadcaster != _state.danmakuBroadcaster &&
        _fullscreenDanmakuController != null) {
      _state.danmakuBroadcaster?.unregister(_fullscreenDanmakuController!);
      newState.danmakuBroadcaster?.register(_fullscreenDanmakuController!);
    }
    setState(() => _state = newState);
  }

  void _registerFullscreenController(DanmakuController controller) {
    _fullscreenDanmakuController = controller;
    _state.danmakuBroadcaster?.register(controller);
  }

  @override
  void dispose() {
    if (_fullscreenDanmakuController != null) {
      _state.danmakuBroadcaster?.unregister(_fullscreenDanmakuController!);
    }
    widget.stateNotifier.removeListener(_onStateChanged);
    _exitFullscreen();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final controller = widget.playerController.videoController;

    if (controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _exitFullscreen();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Video(
                controller: controller,
                controls: NoVideoControls,
                fit: BoxFit.contain,
              ),
            ),
            // 弹幕层：只要弹幕开启就渲染，broadcaster 有值时注册 controller
            if (_state.isDanmakuEnabled)
              Positioned.fill(
                child: DanmakuLayer(
                  onControllerCreated: _registerFullscreenController,
                ),
              ),
            FullscreenVideoControls(
              playerController: widget.playerController,
              title: widget.title,
              currentEpisode: _state.currentEpisode,
              episodeTitle: _state.episodeTitle,
              isDanmakuEnabled: _state.isDanmakuEnabled,
              danmakuController: _state.danmakuController,
              onExitFullscreen: () => Navigator.of(context).pop(),
              onNextEpisode: widget.onNextEpisode,
              onPreviousEpisode: widget.onPreviousEpisode,
              hasNextEpisode: _state.hasNextEpisode,
              hasPreviousEpisode: _state.hasPreviousEpisode,
              episodes: _state.episodes,
              onEpisodeSelected: widget.onEpisodeSelected,
              isLoadingEpisodes: _state.isLoadingEpisodes,
              isDescending: _state.isDescending,
              onToggleSort: widget.onToggleSort,
              onDanmakuToggle: (enabled) {
                DanmakuSettingService().setShowDanmaku(enabled);
                widget.stateNotifier.value = FullscreenVideoState(
                  currentEpisode: _state.currentEpisode,
                  episodes: _state.episodes,
                  isLoadingEpisodes: _state.isLoadingEpisodes,
                  isDescending: _state.isDescending,
                  hasNextEpisode: _state.hasNextEpisode,
                  hasPreviousEpisode: _state.hasPreviousEpisode,
                  episodeTitle: _state.episodeTitle,
                  isDanmakuEnabled: enabled,
                  danmakuController: _state.danmakuController,
                  danmakuBroadcaster: _state.danmakuBroadcaster,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
