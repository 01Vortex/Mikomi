import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mikomi/features/video/facade/fullscreen_page_facade.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/fullscreen_page_state.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/ui/widgets/fullscreen/fullscreen_video.dart';
import 'package:mikomi/features/video/ui/widgets/video_fit.dart';
import 'package:mikomi/features/video/ui/widgets/smallscreen/smallscreen_video.dart';

class FullscreenPage extends StatefulWidget {
  final VideoPlaybackService playbackService;
  final String title;
  final ValueNotifier<FullscreenVideoState> stateNotifier;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final ValueChanged<Episode>? onEpisodeSelected;
  final VoidCallback? onToggleSort;

  const FullscreenPage({
    super.key,
    required this.playbackService,
    required this.title,
    required this.stateNotifier,
    this.onNextEpisode,
    this.onPreviousEpisode,
    this.onEpisodeSelected,
    this.onToggleSort,
  });

  @override
  State<FullscreenPage> createState() => _FullscreenPageState();
}

class _FullscreenPageState extends State<FullscreenPage> {
  late final FullscreenPageFacade _facade;

  @override
  void initState() {
    super.initState();
    _facade = FullscreenPageFacade(
      playbackService: widget.playbackService,
      title: widget.title,
      stateNotifier: widget.stateNotifier,
      onNextEpisode: widget.onNextEpisode,
      onPreviousEpisode: widget.onPreviousEpisode,
      onEpisodeSelected: widget.onEpisodeSelected,
      onToggleSort: widget.onToggleSort,
    );
    unawaited(_facade.initializePage());
  }

  @override
  void dispose() {
    _facade.disposePage();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FullscreenPageState>(
      valueListenable: _facade.stateListenable,
      builder: (context, state, _) {
        if (!state.isVideoReady || state.videoController == null) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        return PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) _facade.handlePagePop();
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Video(
                    controller: state.videoController!,
                    controls: NoVideoControls,
                    fit: state.fitMode.boxFit,
                  ),
                ),
                if (state.videoState.isDanmakuEnabled)
                  Positioned.fill(
                    child: DanmakuLayer(
                      onControllerCreated: _facade.registerFullscreenController,
                      fontSize: state.danmakuConfig.fontSize,
                      opacity: state.danmakuConfig.opacity,
                      speed: state.danmakuConfig.duration,
                      area: state.danmakuConfig.area,
                      strokeWidth: state.danmakuConfig.strokeWidth,
                      hideTop: !state.danmakuConfig.showTop,
                      hideBottom: !state.danmakuConfig.showBottom,
                      hideScroll: !state.danmakuConfig.showScroll,
                    ),
                  ),
                FullscreenVideoControls(
                  playbackService: widget.playbackService,
                  title: widget.title,
                  currentEpisode: state.videoState.currentEpisode,
                  currentSmallTitle: state.videoState.currentSmallTitle,
                  isDanmakuEnabled: state.videoState.isDanmakuEnabled,
                  danmakuController: state.danmakuController,
                  danmakuFacade: state.danmakuController.danmakuFacade,
                  fitMode: state.fitMode,
                  onFitModeChanged: _facade.updateFitMode,
                  onExitFullscreen: () => Navigator.of(context).pop(),
                  onNextEpisode: _facade.onNextEpisode,
                  onPreviousEpisode: _facade.onPreviousEpisode,
                  hasNextEpisode: state.videoState.hasNextEpisode,
                  hasPreviousEpisode: state.videoState.hasPreviousEpisode,
                  episodes: state.videoState.episodes,
                  onEpisodeSelected: _facade.onEpisodeSelected,
                  isLoadingEpisodes: state.videoState.isLoadingEpisodes,
                  isDescending: state.videoState.isDescending,
                  onToggleSort: _facade.onToggleSort,
                  onDanmakuToggle: (enabled) {
                    unawaited(_facade.setDanmakuEnabled(enabled));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
