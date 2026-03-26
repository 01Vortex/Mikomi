import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/ui/widgets/fullscreen_video.dart';
import 'package:mikomi/features/video/ui/widgets/smallscreen_video.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:media_kit_video/media_kit_video.dart';

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

  @override
  void initState() {
    super.initState();
    _state = widget.stateNotifier.value;
    widget.stateNotifier.addListener(_onStateChanged);
    _enterFullscreen();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {
        _state = widget.stateNotifier.value;
      });
    }
  }

  @override
  void dispose() {
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
                fit: BoxFit.cover,
              ),
            ),
            FullscreenVideoControls(
              playerController: widget.playerController,
              title: widget.title,
              currentEpisode: _state.currentEpisode,
              episodeTitle: _state.episodeTitle,
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
            ),
          ],
        ),
      ),
    );
  }
}
