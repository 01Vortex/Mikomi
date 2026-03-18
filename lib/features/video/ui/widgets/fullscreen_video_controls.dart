import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/features/video/controllers/video_player_controller.dart';

class FullscreenVideoControls extends StatefulWidget {
  final VideoPlayerController playerController;
  final String title;
  final int currentEpisode;
  final String? episodeTitle;
  final VoidCallback onExitFullscreen;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final bool hasNextEpisode;
  final bool hasPreviousEpisode;

  const FullscreenVideoControls({
    super.key,
    required this.playerController,
    required this.title,
    required this.currentEpisode,
    this.episodeTitle,
    required this.onExitFullscreen,
    this.onNextEpisode,
    this.onPreviousEpisode,
    this.hasNextEpisode = false,
    this.hasPreviousEpisode = false,
  });

  @override
  State<FullscreenVideoControls> createState() =>
      _FullscreenVideoControlsState();
}

class _FullscreenVideoControlsState extends State<FullscreenVideoControls> {
  bool _showControls = true;
  bool _isPlaying = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isDragging = false;
  bool _isLocked = false;
  Timer? _hideTimer;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _setupListeners() {
    final player = widget.playerController.player;
    if (player == null) return;

    player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });

    player.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() => _isBuffering = buffering);
      }
    });

    player.stream.position.listen((position) {
      if (mounted && !_isDragging) {
        setState(() => _position = position);
      }
    });

    player.stream.duration.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (_isPlaying && !_isLocked) {
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _showControls) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _toggleControls() {
    if (_isLocked) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideTimer();
    }
  }

  void _togglePlayPause() {
    widget.playerController.player?.playOrPause();
    _startHideTimer();
  }

  void _seekForward() {
    final newPosition = _position + const Duration(seconds: 10);
    widget.playerController.player?.seek(
      newPosition > _duration ? _duration : newPosition,
    );
  }

  void _seekBackward() {
    final newPosition = _position - const Duration(seconds: 10);
    widget.playerController.player?.seek(
      newPosition < Duration.zero ? Duration.zero : newPosition,
    );
  }

  void _showSpeedSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '播放速度',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...[0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
              return ListTile(
                title: Text(
                  '${speed}x',
                  style: TextStyle(
                    color: _playbackSpeed == speed
                        ? AppColors.primary
                        : Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                selected: _playbackSpeed == speed,
                onTap: () {
                  setState(() => _playbackSpeed = speed);
                  widget.playerController.player?.setRate(speed);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 缓冲指示器
            if (_isBuffering) _buildBufferingIndicator(),

            // 顶部渐变
            if (_showControls && !_isLocked) _buildTopGradient(),

            // 底部渐变
            if (_showControls && !_isLocked) _buildBottomGradient(),

            // 顶部控制栏
            if (_showControls && !_isLocked) _buildTopBar(),

            // 中间播放控制
            if (_showControls && !_isLocked) _buildCenterControls(),

            // 底部控制栏
            if (_showControls && !_isLocked) _buildBottomControls(),

            // 锁定按钮
            _buildLockButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: widget.onExitFullscreen,
              ),
              const SizedBox(width: 8),
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
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.episodeTitle != null &&
                        widget.episodeTitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '第${widget.currentEpisode}集 ${widget.episodeTitle}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.hasPreviousEpisode)
            _buildControlButton(
              icon: Icons.skip_previous,
              onTap: widget.onPreviousEpisode ?? () {},
            ),
          if (widget.hasPreviousEpisode) const SizedBox(width: 24),
          _buildControlButton(icon: Icons.replay_10, onTap: _seekBackward),
          const SizedBox(width: 40),
          _buildControlButton(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            onTap: _togglePlayPause,
            size: 64,
          ),
          const SizedBox(width: 40),
          _buildControlButton(icon: Icons.forward_10, onTap: _seekForward),
          if (widget.hasNextEpisode) const SizedBox(width: 24),
          if (widget.hasNextEpisode)
            _buildControlButton(
              icon: Icons.skip_next,
              onTap: widget.onNextEpisode ?? () {},
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 48,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.6),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 进度条
              Row(
                children: [
                  Text(
                    _formatDuration(_position),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
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
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                        thumbColor: AppColors.primary,
                      ),
                      child: Slider(
                        value: _duration.inMilliseconds > 0
                            ? _position.inMilliseconds /
                                  _duration.inMilliseconds
                            : 0.0,
                        onChanged: (value) {
                          setState(() {
                            _isDragging = true;
                            _position = Duration(
                              milliseconds: (value * _duration.inMilliseconds)
                                  .toInt(),
                            );
                          });
                        },
                        onChangeEnd: (value) {
                          _isDragging = false;
                          widget.playerController.player?.seek(_position);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 底部按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildBottomButton(
                    icon: Icons.speed,
                    label: '${_playbackSpeed}x',
                    onTap: _showSpeedSelector,
                  ),
                  const SizedBox(width: 12),
                  _buildBottomButton(
                    icon: Icons.fullscreen_exit,
                    label: '退出全屏',
                    onTap: widget.onExitFullscreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
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
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isLocked = !_isLocked;
            if (_isLocked) {
              _showControls = false;
              _hideTimer?.cancel();
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isLocked ? Icons.lock : Icons.lock_open,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
