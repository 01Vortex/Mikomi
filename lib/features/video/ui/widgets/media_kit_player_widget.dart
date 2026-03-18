import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mikomi/features/video/controllers/video_player_controller.dart';

class MediaKitPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String title;
  final int currentEpisode;
  final int totalEpisodes;
  final VideoPlayerController playerController;
  final String? episodeTitle;
  final VoidCallback? onBack;
  final VoidCallback? onOpenMenu;

  const MediaKitPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.currentEpisode,
    required this.totalEpisodes,
    required this.playerController,
    this.episodeTitle,
    this.onBack,
    this.onOpenMenu,
  });

  @override
  State<MediaKitPlayerWidget> createState() => _MediaKitPlayerWidgetState();
}

class _MediaKitPlayerWidgetState extends State<MediaKitPlayerWidget> {
  bool _isLoading = true;
  bool _isBuffering = false;
  bool _showControls = true;
  String? _errorMessage;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isDragging = false;
  bool _lockPanel = false;
  Timer? _hideTimer;

  // 手势控制相关(预留)
  Timer? _hideVolumeUITimer;
  Timer? _hideBrightnessUITimer;

  // 双击控制
  int _doubleTapCount = 0;
  Timer? _doubleTapTimer;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _startControlsTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hideVolumeUITimer?.cancel();
    _hideBrightnessUITimer?.cancel();
    _doubleTapTimer?.cancel();
    super.dispose();
  }

  void _startControlsTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && !_lockPanel) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    if (_lockPanel) return;
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.playerController.initialize();

      if (mounted && widget.videoUrl.isNotEmpty) {
        await widget.playerController.play(widget.videoUrl);

        final player = widget.playerController.player;
        if (player != null) {
          player.stream.buffering.listen((buffering) {
            if (mounted) {
              setState(() {
                _isBuffering = buffering;
              });
            }
          });

          player.stream.playing.listen((playing) {
            if (mounted) {
              setState(() {
                _isPlaying = playing;
              });
            }
          });

          player.stream.position.listen((position) {
            if (mounted && !_isDragging) {
              setState(() {
                _currentPosition = position;
              });
            }
          });

          player.stream.duration.listen((duration) {
            if (mounted) {
              setState(() {
                _totalDuration = duration;
              });
            }
          });
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '视频加载失败: $e';
        });
      }
    }
  }

  @override
  void didUpdateWidget(MediaKitPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl && widget.videoUrl.isNotEmpty) {
      _initPlayer();
    }
  }

  void _togglePlayPause() {
    final player = widget.playerController.player;
    if (player == null) return;

    if (_isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _seekTo(Duration position) {
    final player = widget.playerController.player;
    if (player == null) return;
    player.seek(position);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  void _handleTap() {
    _toggleControls();
  }

  void _handleDoubleTap() {
    _doubleTapCount++;
    _doubleTapTimer?.cancel();

    if (_doubleTapCount == 1) {
      _doubleTapTimer = Timer(const Duration(milliseconds: 300), () {
        _doubleTapCount = 0;
      });
    } else if (_doubleTapCount == 2) {
      _togglePlayPause();
      _doubleTapCount = 0;
      _doubleTapTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    final controller = widget.playerController.videoController;

    if (_isLoading ||
        !widget.playerController.isInitialized ||
        controller == null) {
      return _buildLoadingWidget();
    }

    return GestureDetector(
      onTap: _handleTap,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        children: [
          // 视频播放器
          Positioned.fill(
            child: Video(controller: controller, controls: NoVideoControls),
          ),

          // 缓冲指示器
          if (_isBuffering) _buildBufferingIndicator(),

          // 顶部渐变遮罩
          if (_showControls && !_lockPanel) _buildTopGradient(),

          // 底部渐变遮罩
          if (_showControls && !_lockPanel) _buildBottomGradient(),

          // 顶部控制栏
          if (_showControls && !_lockPanel) _buildTopControls(),

          // 底部控制栏
          if (_showControls && !_lockPanel) _buildBottomControls(),

          // 锁定按钮
          _buildLockButton(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white70, size: 48),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: _initPlayer, child: const Text('重试')),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, right: 4, top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24,
            ),
            const SizedBox(width: 4),
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
                  if (widget.episodeTitle != null &&
                      widget.episodeTitle!.isNotEmpty)
                    Text(
                      '第${widget.currentEpisode}集 ${widget.episodeTitle}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      '第${widget.currentEpisode}集',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
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
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Row(
          children: [
            // 播放/暂停按钮
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _togglePlayPause,
            ),
            // 当前时间
            Text(
              _formatDuration(_currentPosition),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            // 进度条
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  activeTrackColor: Theme.of(context).colorScheme.primary,
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                  thumbColor: Theme.of(context).colorScheme.primary,
                  overlayColor: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
                child: Slider(
                  value: _totalDuration.inMilliseconds > 0
                      ? _currentPosition.inMilliseconds /
                            _totalDuration.inMilliseconds
                      : 0.0,
                  onChanged: (value) {
                    setState(() {
                      _isDragging = true;
                      _currentPosition = Duration(
                        milliseconds: (value * _totalDuration.inMilliseconds)
                            .toInt(),
                      );
                    });
                  },
                  onChangeEnd: (value) {
                    final position = Duration(
                      milliseconds: (value * _totalDuration.inMilliseconds)
                          .toInt(),
                    );
                    _seekTo(position);
                    setState(() {
                      _isDragging = false;
                    });
                  },
                ),
              ),
            ),
            // 总时长
            Text(
              _formatDuration(_totalDuration),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            // 全屏按钮
            IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.white, size: 28),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockButton() {
    return Positioned(
      left: 16,
      top: MediaQuery.of(context).size.height / 2 - 24,
      child: IconButton(
        icon: Icon(
          _lockPanel ? Icons.lock : Icons.lock_open,
          color: Colors.white.withValues(alpha: _lockPanel ? 1.0 : 0.5),
        ),
        onPressed: () {
          setState(() {
            _lockPanel = !_lockPanel;
            if (_lockPanel) {
              _showControls = false;
            }
          });
        },
      ),
    );
  }
}
