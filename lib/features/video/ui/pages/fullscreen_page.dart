import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/fullscreen_video_state.dart';
import 'package:mikomi/features/video/state/video_player_listener.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/ui/widgets/fullscreen/fullscreen_video.dart';
import 'package:mikomi/features/video/ui/widgets/video_fit.dart';

class FullscreenPage extends StatefulWidget {
  final VideoPlaybackService playbackService;
  final String title;
  final ValueNotifier<FullscreenVideoState> stateNotifier;
  final ValueListenable<VideoPlayerSnapshot> playerSnapshotListenable;
  final DanmakuConfig danmakuConfig;
  final bool isDanmakuInputVisible;
  final VideoFitMode fitMode;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final ValueChanged<Episode>? onEpisodeSelected;
  final VoidCallback? onToggleSort;
  final ValueChanged<VideoFitMode> onFitModeChanged;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<double> onPlaybackSpeedChanged;
  final ValueChanged<DanmakuConfig> onDanmakuConfigChanged;
  final ValueChanged<bool>? onDanmakuToggle;
  final ValueChanged<bool> onDanmakuInputVisibleChanged;
  final ValueChanged<dynamic> onFullscreenDanmakuLayerCreated;

  const FullscreenPage({
    super.key,
    required this.playbackService,
    required this.title,
    required this.stateNotifier,
    required this.playerSnapshotListenable,
    required this.danmakuConfig,
    required this.isDanmakuInputVisible,
    required this.fitMode,
    this.onNextEpisode,
    this.onPreviousEpisode,
    this.onEpisodeSelected,
    this.onToggleSort,
    required this.onFitModeChanged,
    required this.onPlayPause,
    required this.onSeek,
    required this.onPlaybackSpeedChanged,
    required this.onDanmakuConfigChanged,
    this.onDanmakuToggle,
    required this.onDanmakuInputVisibleChanged,
    required this.onFullscreenDanmakuLayerCreated,
  });

  @override
  State<FullscreenPage> createState() => _FullscreenPageState();
}

class _FullscreenPageState extends State<FullscreenPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.playbackService.videoController;
    if (controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return ValueListenableBuilder<FullscreenVideoState>(
      valueListenable: widget.stateNotifier,
      builder: (context, state, _) {
        return PopScope(
          canPop: true,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Video(
                    controller: controller,
                    controls: NoVideoControls,
                    fit: widget.fitMode.boxFit,
                  ),
                ),
                if (state.isDanmakuEnabled)
                  Positioned.fill(
                    child: DanmakuLayer(
                      onControllerCreated:
                          widget.onFullscreenDanmakuLayerCreated,
                      fontSize: widget.danmakuConfig.fontSize,
                      opacity: widget.danmakuConfig.opacity,
                      speed: widget.danmakuConfig.duration,
                      area: widget.danmakuConfig.area,
                      strokeWidth: widget.danmakuConfig.strokeWidth,
                      hideTop: !widget.danmakuConfig.showTop,
                      hideBottom: !widget.danmakuConfig.showBottom,
                      hideScroll: !widget.danmakuConfig.showScroll,
                    ),
                  ),
                FullscreenVideoControls(
                  playbackService: widget.playbackService,
                  playerSnapshotListenable: widget.playerSnapshotListenable,
                  danmakuConfig: widget.danmakuConfig,
                  isDanmakuInputVisible: widget.isDanmakuInputVisible,
                  onDanmakuInputVisibleChanged:
                      widget.onDanmakuInputVisibleChanged,
                  onPlaybackSpeedChanged: widget.onPlaybackSpeedChanged,
                  onSeek: widget.onSeek,
                  onPlayPause: widget.onPlayPause,
                  onDanmakuConfigChanged: widget.onDanmakuConfigChanged,
                  title: widget.title,
                  currentEpisode: state.currentEpisode,
                  currentSmallTitle: state.currentSmallTitle,
                  isDanmakuEnabled: state.isDanmakuEnabled,
                  fitMode: widget.fitMode,
                  onFitModeChanged: widget.onFitModeChanged,
                  onExitFullscreen: () => Navigator.of(context).pop(),
                  onNextEpisode: widget.onNextEpisode,
                  onPreviousEpisode: widget.onPreviousEpisode,
                  hasNextEpisode: state.hasNextEpisode,
                  hasPreviousEpisode: state.hasPreviousEpisode,
                  episodes: state.episodes,
                  onEpisodeSelected: widget.onEpisodeSelected,
                  isLoadingEpisodes: state.isLoadingEpisodes,
                  isDescending: state.isDescending,
                  onToggleSort: widget.onToggleSort,
                  onDanmakuToggle: widget.onDanmakuToggle,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
