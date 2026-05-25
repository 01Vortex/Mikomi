import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mikomi/features/video/controller/video_page_controller.dart';
import 'package:mikomi/features/video/state/fullscreen_video_state.dart';
import 'package:mikomi/features/video/state/video_page_state.dart';
import 'package:mikomi/features/video/state/video_player_listener.dart';
import 'package:mikomi/features/video/ui/pages/fullscreen_page.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/ui/widgets/player/video_gesture.dart';

/// 小屏视频播放器控件。
///
/// 重构后：接受 [VideoPageController] + [VideoPageState] 替代原来的 30 个独立回调参数。
class SmallscreenVideo extends StatefulWidget {
  final VideoPageState pageState;
  final VideoPageController controller;
  final void Function(bool enabled)? onDanmakuToggle;

  const SmallscreenVideo({
    super.key,
    required this.pageState,
    required this.controller,
    this.onDanmakuToggle,
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
    _fullscreenNotifier = ValueNotifier(widget.pageState.fullscreenState);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final url = widget.pageState.player.resolvedVideoUrl;
        widget.controller.initializeSmallScreenPlayback(url);
      }
    });
    _startControlsTimer();
  }

  @override
  void didUpdateWidget(covariant SmallscreenVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFullscreenState(widget.pageState.fullscreenState);
    if (oldWidget.pageState.player.resolvedVideoUrl !=
            widget.pageState.player.resolvedVideoUrl &&
        widget.pageState.player.resolvedVideoUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.controller.initializeSmallScreenPlayback(
            widget.pageState.player.resolvedVideoUrl,
          );
        }
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
      if (pending != null) _fullscreenNotifier.value = pending;
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
    widget.controller.togglePlayPause();
    _doubleTapCount = 0;
  }

  void _enterFullscreen() {
    final before = widget.pageState.player.isDanmakuEnabled;
    final ctrl = widget.controller;
    final state = widget.pageState;
    Navigator.of(context)
        .push(
          PageRouteBuilder(
            pageBuilder: (_, animation, secondaryAnimation) => FullscreenPage(
              controller: ctrl,
              playbackService: state.playbackService,
              title: state.title,
              stateNotifier: _fullscreenNotifier,
              playerSnapshotListenable: state.playerSnapshotListenable,
              danmakuConfig: state.danmakuConfig,
              isDanmakuInputVisible: state.player.isDanmakuEnabled,
              fitMode: state.fullscreenFitMode,
              onDanmakuToggle: widget.onDanmakuToggle,
              onDanmakuInputVisibleChanged: (_) {},
            ),
            transitionDuration: const Duration(milliseconds: 200),
            reverseTransitionDuration: const Duration(milliseconds: 200),
            transitionsBuilder: (_, animation, secondaryAnimation, child) => FadeTransition(
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
    final ss = widget.pageState.smallscreen;
    final showPlayer = ss.showPlayer;

    return VideoGesture(
      playbackService: widget.pageState.playbackService,
      enabled: showPlayer && !_lockPanel,
      child: GestureDetector(
        onTap: showPlayer ? _toggleControls : null,
        onDoubleTap: showPlayer ? _handleDoubleTap : null,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.black)),
            if (showPlayer)
              Positioned.fill(
                child: RepaintBoundary(
                  child: Video(
                    controller: ss.videoController!,
                    controls: NoVideoControls,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            if (showPlayer && widget.pageState.player.isDanmakuEnabled)
              _danmakuLayer(),
            if (ss.isLoading) _loading(),
            if (ss.error != null) _error(ss.error!),
            if (showPlayer && _showControls && !_lockPanel)
              _gradient(top: true),
            if (showPlayer && _showControls && !_lockPanel)
              _gradient(top: false),
            if (!showPlayer || (_showControls && !_lockPanel))
              _topControls(),
            if (showPlayer) _lockButton(),
            // 仅以下控件需要每帧 snapshot 数据（进度/播放状态）
            if (showPlayer)
              Positioned.fill(
                child: ValueListenableBuilder<VideoPlayerSnapshot>(
                  valueListenable: widget.pageState.playerSnapshotListenable,
                  builder: (context, snapshot, _) {
                    final position =
                        _isDragging ? _dragPosition : snapshot.position;
                    final showCtrls = _showControls && !_lockPanel;
                    return Stack(
                      children: [
                        if (snapshot.isBuffering) _buffering(),
                        if (showCtrls)
                          _bottomControls(
                            snapshot.isPlaying,
                            position,
                            snapshot.duration,
                          ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _danmakuLayer() {
    final c = widget.pageState.danmakuConfig;
    return Positioned.fill(
      child: DanmakuLayer(
        onControllerCreated: widget.controller.attachSmallScreenDanmakuController,
        onControllerDisposed: widget.controller.detachDanmakuController,
        fontSize: c.fontSize,
        opacity: c.opacity,
        speed: c.duration,
        area: c.area,
        strokeWidth: c.strokeWidth,
        hideTop: !c.showTop,
        hideBottom: !c.showBottom,
        hideScroll: !c.showScroll,
      ),
    );
  }

  Widget _loading() => const Positioned.fill(
    child: Center(
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
    ),
  );

  Widget _error(Object error) => Positioned.fill(
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 48),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => widget.controller.retrySmallScreenPlayback(),
            child: const Text('重试'),
          ),
        ],
      ),
    ),
  );

  Widget _buffering() => Positioned.fill(
    child: Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            SizedBox(height: 12),
            Text(
              '缓冲中...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
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

  Widget _topControls() {
    final p = widget.pageState.player;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.only(left: 8, right: 4, top: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
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
                    widget.pageState.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    p.currentSmallTitle != null &&
                            p.currentSmallTitle!.isNotEmpty
                        ? '第${p.currentEpisodeNumber}集 ${p.currentSmallTitle}'
                        : '第${p.currentEpisodeNumber}集',
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
          ],
        ),
      ),
    );
  }

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
            onPressed: widget.controller.togglePlayPause,
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
                widget.controller.seekTo(
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
