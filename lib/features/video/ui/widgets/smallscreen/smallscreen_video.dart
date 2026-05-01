import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/fullscreen_video_state.dart';
import 'package:mikomi/features/video/state/video_page_state.dart';
import 'package:mikomi/features/video/state/video_player_listener.dart';
import 'package:mikomi/features/video/ui/pages/fullscreen_page.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/ui/widgets/video_fit.dart';
import 'package:mikomi/features/video/ui/widgets/video_gesture.dart';

class SmallscreenVideo extends StatefulWidget {
  final String videoUrl;
  final String title;
  final int currentEpisode;
  final int totalEpisodes;
  final VideoPlaybackService playbackService;
  final SmallscreenPlaybackState playbackState;
  final ValueListenable<VideoPlayerSnapshot> playerSnapshotListenable;
  final DanmakuConfig danmakuConfig;
  final FullscreenVideoState fullscreenState;
  final VideoFitMode fullscreenFitMode;
  final String? currentSmallTitle;
  final VoidCallback? onBack;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final bool hasNextEpisode;
  final bool hasPreviousEpisode;
  final List<Episode> episodes;
  final Function(Episode)? onEpisodeSelected;
  final bool isLoadingEpisodes;
  final bool isDescending;
  final VoidCallback? onToggleSort;
  final bool isDanmakuEnabled;
  final void Function(bool)? onDanmakuToggle;
  final VoidCallback onInitializePlayer;
  final VoidCallback onRetryPlayer;
  final VoidCallback onTogglePlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<dynamic> onDanmakuLayerCreated;
  final ValueChanged<VideoFitMode> onFullscreenFitModeChanged;
  final ValueChanged<double> onPlaybackSpeedChanged;
  final ValueChanged<DanmakuConfig> onDanmakuConfigChanged;

  const SmallscreenVideo({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.currentEpisode,
    required this.totalEpisodes,
    required this.playbackService,
    required this.playbackState,
    required this.playerSnapshotListenable,
    required this.danmakuConfig,
    required this.fullscreenState,
    required this.fullscreenFitMode,
    this.currentSmallTitle,
    this.onBack,
    this.onOpenMenu,
    this.onNextEpisode,
    this.onPreviousEpisode,
    this.hasNextEpisode = false,
    this.hasPreviousEpisode = false,
    this.episodes = const [],
    this.onEpisodeSelected,
    this.isLoadingEpisodes = false,
    this.isDescending = false,
    this.onToggleSort,
    this.isDanmakuEnabled = false,
    this.onDanmakuToggle,
    required this.onInitializePlayer,
    required this.onRetryPlayer,
    required this.onTogglePlayPause,
    required this.onSeek,
    required this.onDanmakuLayerCreated,
    required this.onFullscreenFitModeChanged,
    required this.onPlaybackSpeedChanged,
    required this.onDanmakuConfigChanged,
  });

  @override
  State<SmallscreenVideo> createState() => _SmallscreenVideoState();
}

class _SmallscreenVideoState extends State<SmallscreenVideo> {
  late final ValueNotifier<FullscreenVideoState> _fullscreenNotifier;
  FullscreenVideoState? _pendingFullscreenState;
  bool _showControls = true;
  bool _isDragging = false;
  bool _lockPanel = false;
  Duration _dragPosition = Duration.zero;
  Timer? _hideTimer;
  int _doubleTapCount = 0;
  Timer? _doubleTapTimer;

  @override
  void initState() {
    super.initState();
    _fullscreenNotifier = ValueNotifier(widget.fullscreenState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onInitializePlayer();
    });
    _startControlsTimer();
  }

  @override
  void didUpdateWidget(covariant SmallscreenVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFullscreenState(widget.fullscreenState);
    if (oldWidget.videoUrl != widget.videoUrl && widget.videoUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onInitializePlayer();
      });
    }
  }

  void _syncFullscreenState(FullscreenVideoState state) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    final shouldDefer =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks;

    if (!shouldDefer) {
      _fullscreenNotifier.value = state;
      return;
    }

    _pendingFullscreenState = state;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = _pendingFullscreenState;
      _pendingFullscreenState = null;
      if (pending != null) {
        _fullscreenNotifier.value = pending;
      }
    });
  }

  @override
  void dispose() {
    _fullscreenNotifier.dispose();
    _hideTimer?.cancel();
    _doubleTapTimer?.cancel();
    super.dispose();
  }

  void _startControlsTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && !_lockPanel) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    if (_lockPanel) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) _startControlsTimer();
  }

  void _handleDoubleTap() {
    _doubleTapCount++;
    _doubleTapTimer?.cancel();
    if (_doubleTapCount == 1) {
      _doubleTapTimer = Timer(
        const Duration(milliseconds: 300),
        () => _doubleTapCount = 0,
      );
      return;
    }
    widget.onTogglePlayPause();
    _doubleTapCount = 0;
  }

  void _enterFullscreen() {
    final before = widget.isDanmakuEnabled;
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (_, _, _) => FullscreenPage(
              playbackService: widget.playbackService,
              title: widget.title,
              stateNotifier: _fullscreenNotifier,
              onNextEpisode: widget.onNextEpisode,
              onPreviousEpisode: widget.onPreviousEpisode,
              onEpisodeSelected: widget.onEpisodeSelected,
              onToggleSort: widget.onToggleSort,
              playerSnapshotListenable: widget.playerSnapshotListenable,
              danmakuConfig: widget.danmakuConfig,
              isDanmakuInputVisible: widget.isDanmakuEnabled,
              fitMode: widget.fullscreenFitMode,
              onFitModeChanged: widget.onFullscreenFitModeChanged,
              onPlayPause: widget.onTogglePlayPause,
              onSeek: widget.onSeek,
              onPlaybackSpeedChanged: widget.onPlaybackSpeedChanged,
              onDanmakuConfigChanged: widget.onDanmakuConfigChanged,
              onDanmakuToggle: widget.onDanmakuToggle,
              onDanmakuInputVisibleChanged: (_) {},
              onFullscreenDanmakuLayerCreated: widget.onDanmakuLayerCreated,
            ),
            transitionDuration: const Duration(milliseconds: 200),
            reverseTransitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder: (_, animation, _, child) => FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            ),
          ),
        )
        .then((_) {
          final after = _fullscreenNotifier.value.isDanmakuEnabled;
          if (after != before) widget.onDanmakuToggle?.call(after);
        });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerSnapshot>(
      valueListenable: widget.playerSnapshotListenable,
      builder: (context, snapshot, _) {
        final state = widget.playbackState;
        final showPlayer = state.showPlayer;
        final position = _isDragging ? _dragPosition : snapshot.position;
        return VideoGesture(
          playbackService: widget.playbackService,
          enabled: showPlayer && !_lockPanel,
          child: GestureDetector(
            onTap: showPlayer ? _toggleControls : null,
            onDoubleTap: showPlayer ? _handleDoubleTap : null,
            child: Stack(
              children: [
                Positioned.fill(child: Container(color: Colors.black)),
                if (showPlayer)
                  Positioned.fill(
                    child: Video(
                      controller: state.videoController!,
                      controls: NoVideoControls,
                      fit: BoxFit.contain,
                    ),
                  ),
                if (showPlayer && widget.isDanmakuEnabled) _danmakuLayer(),
                if (state.isLoading) _loading(),
                if (state.errorMessage != null) _error(state.errorMessage!),
                if (showPlayer && snapshot.isBuffering) _buffering(),
                if (showPlayer && _showControls && !_lockPanel)
                  _gradient(top: true),
                if (showPlayer && _showControls && !_lockPanel)
                  _gradient(top: false),
                if (!showPlayer || (_showControls && !_lockPanel))
                  _topControls(),
                if (showPlayer && _showControls && !_lockPanel)
                  _bottomControls(
                    snapshot.isPlaying,
                    position,
                    snapshot.duration,
                  ),
                if (showPlayer) _lockButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _danmakuLayer() => Positioned.fill(
    child: DanmakuLayer(
      onControllerCreated: widget.onDanmakuLayerCreated,
      fontSize: widget.danmakuConfig.fontSize,
      opacity: widget.danmakuConfig.opacity,
      speed: widget.danmakuConfig.duration,
      area: widget.danmakuConfig.area,
      strokeWidth: widget.danmakuConfig.strokeWidth,
      hideTop: !widget.danmakuConfig.showTop,
      hideBottom: !widget.danmakuConfig.showBottom,
      hideScroll: !widget.danmakuConfig.showScroll,
    ),
  );

  Widget _loading() => const Positioned.fill(
    child: Center(
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
    ),
  );

  Widget _error(String message) => Positioned.fill(
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: widget.onRetryPlayer, child: const Text('重试')),
        ],
      ),
    ),
  );

  Widget _buffering() => Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            const SizedBox(height: 12),
            Text(
              '缓冲中...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _gradient({required bool top}) => Positioned(
    top: top ? 0 : null,
    bottom: top ? null : 0,
    left: 0,
    right: 0,
    child: Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: top ? Alignment.topCenter : Alignment.bottomCenter,
          end: top ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
    ),
  );

  Widget _topControls() => Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: Padding(
      padding: const EdgeInsets.only(left: 8, right: 4, top: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack ?? () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.currentSmallTitle != null &&
                          widget.currentSmallTitle!.isNotEmpty
                      ? '第${widget.currentEpisode}集 ${widget.currentSmallTitle}'
                      : '第${widget.currentEpisode}集',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (widget.onOpenMenu != null)
            IconButton(
              icon: const Icon(Icons.menu_open, color: Colors.white),
              onPressed: widget.onOpenMenu,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24,
            ),
        ],
      ),
    ),
  );

  Widget _bottomControls(
    bool isPlaying,
    Duration position,
    Duration duration,
  ) => Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: SafeArea(
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
            onPressed: widget.onTogglePlayPause,
          ),
          Text(
            formatVideoDuration(position),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          Expanded(
            child: Slider(
              value: duration.inMilliseconds > 0
                  ? position.inMilliseconds / duration.inMilliseconds
                  : 0,
              onChanged: (value) => setState(() {
                _isDragging = true;
                _dragPosition = Duration(
                  milliseconds: (value * duration.inMilliseconds).toInt(),
                );
              }),
              onChangeEnd: (value) {
                widget.onSeek(
                  Duration(
                    milliseconds: (value * duration.inMilliseconds).toInt(),
                  ),
                );
                setState(() => _isDragging = false);
              },
            ),
          ),
          Text(
            formatVideoDuration(duration),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen, color: Colors.white, size: 28),
            onPressed: _enterFullscreen,
          ),
        ],
      ),
    ),
  );

  Widget _lockButton() => Positioned(
    left: 16,
    top: MediaQuery.of(context).size.height / 2 - 24,
    child: IconButton(
      icon: Icon(
        _lockPanel ? Icons.lock : Icons.lock_open,
        color: Colors.white.withValues(alpha: _lockPanel ? 1 : 0.5),
      ),
      onPressed: () => setState(() {
        _lockPanel = !_lockPanel;
        if (_lockPanel) _showControls = false;
      }),
    ),
  );
}
