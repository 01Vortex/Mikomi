import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/video/controller/video_page_controller.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/fullscreen_video_state.dart';
import 'package:mikomi/features/video/state/video_player_listener.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/ui/widgets/fullscreen/fullscreen_video.dart';
import 'package:mikomi/features/video/ui/widgets/video_fit.dart';

class FullscreenPage extends StatefulWidget {
  final VideoPageController controller;
  final VideoPlaybackService playbackService;
  final String title;
  final ValueNotifier<FullscreenVideoState> stateNotifier;
  final ValueListenable<VideoPlayerSnapshot> playerSnapshotListenable;
  final DanmakuConfig danmakuConfig;
  final bool isDanmakuInputVisible;
  final VideoFitMode fitMode;
  final ValueChanged<bool>? onDanmakuToggle;
  final ValueChanged<bool> onDanmakuInputVisibleChanged;

  const FullscreenPage({
    super.key,
    required this.controller,
    required this.playbackService,
    required this.title,
    required this.stateNotifier,
    required this.playerSnapshotListenable,
    required this.danmakuConfig,
    required this.isDanmakuInputVisible,
    required this.fitMode,
    this.onDanmakuToggle,
    required this.onDanmakuInputVisibleChanged,
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
    final videoCtrl = widget.playbackService.videoController;
    if (videoCtrl == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final ctrl = widget.controller;
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
                    controller: videoCtrl,
                    controls: NoVideoControls,
                    fit: widget.fitMode.boxFit,
                  ),
                ),
                if (state.isDanmakuEnabled)
                  Positioned.fill(
                    child: DanmakuLayer(
                      onControllerCreated:
                          ctrl.attachFullscreenDanmakuController,
                      onControllerDisposed: ctrl.detachDanmakuController,
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
                  controller: ctrl,
                  playbackService: widget.playbackService,
                  playerSnapshotListenable: widget.playerSnapshotListenable,
                  danmakuConfig: widget.danmakuConfig,
                  isDanmakuInputVisible: widget.isDanmakuInputVisible,
                  onDanmakuInputVisibleChanged:
                      widget.onDanmakuInputVisibleChanged,
                  title: widget.title,
                  fitMode: widget.fitMode,
                  state: state,
                  onExitFullscreen: () => Navigator.of(context).pop(),
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
