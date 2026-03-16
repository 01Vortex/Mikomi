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

  const MediaKitPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.currentEpisode,
    required this.totalEpisodes,
    required this.playerController,
    this.episodeTitle,
  });

  @override
  State<MediaKitPlayerWidget> createState() => _MediaKitPlayerWidgetState();
}

class _MediaKitPlayerWidgetState extends State<MediaKitPlayerWidget> {
  bool _isLoading = true;
  bool _isBuffering = false;
  bool _showControls = true;
  String? _errorMessage;
  double _bufferSpeed = 0.0; // KB/s
  int _lastBufferedBytes = 0;
  DateTime _lastUpdateTime = DateTime.now();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _startSpeedMonitoring();
    _startControlsTimer();
  }

  void _startControlsTimer() {
    // 3秒后自动隐藏控制器
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
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
        debugPrint('开始自动播放视频: ${widget.videoUrl}');
        await widget.playerController.play(widget.videoUrl);

        final player = widget.playerController.player;
        if (player != null) {
          // 监听缓冲状态
          player.stream.buffering.listen((buffering) {
            if (mounted) {
              setState(() {
                _isBuffering = buffering;
              });
            }
          });

          // 监听播放状态
          player.stream.playing.listen((playing) {
            if (mounted) {
              setState(() {
                _isPlaying = playing;
              });
            }
          });

          // 监听播放进度
          player.stream.position.listen((position) {
            if (mounted && !_isDragging) {
              setState(() {
                _currentPosition = position;
              });
            }
          });

          // 监听总时长
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
      debugPrint('播放器初始化失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '视频加载失败: $e';
        });
      }
    }
  }

  void _startSpeedMonitoring() {
    // 每秒更新一次网速
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      final player = widget.playerController.player;
      if (player != null) {
        // 监听缓冲进度来计算网速
        player.stream.buffer.listen((buffer) {
          if (!mounted) return;

          final now = DateTime.now();
          final timeDiff = now.difference(_lastUpdateTime).inMilliseconds;

          if (timeDiff >= 1000) {
            // 估算网速（这是一个简化的实现）
            final currentBytes = (buffer.inMilliseconds / 1000 * 1024 * 100)
                .toInt();
            final bytesDiff = currentBytes - _lastBufferedBytes;
            final speed = (bytesDiff / (timeDiff / 1000)) / 1024; // KB/s

            setState(() {
              _bufferSpeed = speed > 0 ? speed : 0;
              _lastBufferedBytes = currentBytes;
              _lastUpdateTime = now;
            });
          }
        });
      }

      _startSpeedMonitoring();
    });
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

  void _seekRelative(int seconds) {
    final newPosition = _currentPosition + Duration(seconds: seconds);
    if (newPosition < Duration.zero) {
      _seekTo(Duration.zero);
    } else if (newPosition > _totalDuration) {
      _seekTo(_totalDuration);
    } else {
      _seekTo(newPosition);
    }
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

  Widget _buildCenterButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 56,
    double iconSize = 32,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
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

    final controller = widget.playerController.videoController;

    if (_isLoading ||
        !widget.playerController.isInitialized ||
        controller == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  '${_bufferSpeed.toStringAsFixed(0)} KB/s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        GestureDetector(
          onTap: _toggleControls,
          child: Video(controller: controller, controls: NoVideoControls),
        ),
        // 顶部标题栏（在状态栏下方）
        if (_showControls)
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
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
                              widget.episodeTitle!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '第${widget.currentEpisode}集 ${widget.episodeTitle}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ] else
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
                  ],
                ),
              ),
            ),
          ),
        // 缓冲时在中心显示加载圈和网速
        if (_isBuffering)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${_bufferSpeed.toStringAsFixed(0)} KB/s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // 中心控制区域（播放/暂停、快进/快退）
        if (_showControls && !_isBuffering)
          Positioned.fill(
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 快退10秒
                  _buildCenterButton(
                    icon: Icons.replay_10,
                    onTap: () => _seekRelative(-10),
                  ),
                  const SizedBox(width: 40),
                  // 播放/暂停
                  _buildCenterButton(
                    icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                    onTap: _togglePlayPause,
                    size: 72,
                    iconSize: 48,
                  ),
                  const SizedBox(width: 40),
                  // 快进10秒
                  _buildCenterButton(
                    icon: Icons.forward_10,
                    onTap: () => _seekRelative(10),
                  ),
                ],
              ),
            ),
          ),
        // 顶部进度条（紧贴视频画面）
        if (_showControls && !_isBuffering)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                height: 4,
                color: Colors.black.withValues(alpha: 0.3),
                child: LinearProgressIndicator(
                  value: _totalDuration.inMilliseconds > 0
                      ? _currentPosition.inMilliseconds /
                            _totalDuration.inMilliseconds
                      : 0.0,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
        // 底部控制栏（毛玻璃效果）
        if (_showControls && !_isBuffering)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // 播放/暂停按钮
                    _buildControlButton(
                      icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                      onPressed: _togglePlayPause,
                    ),
                    const SizedBox(width: 8),
                    // 时间显示和进度条
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 可拖动的进度条
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 10,
                              ),
                              activeTrackColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              inactiveTrackColor: Colors.white.withValues(
                                alpha: 0.3,
                              ),
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
                                    milliseconds:
                                        (value * _totalDuration.inMilliseconds)
                                            .toInt(),
                                  );
                                });
                              },
                              onChangeEnd: (value) {
                                final position = Duration(
                                  milliseconds:
                                      (value * _totalDuration.inMilliseconds)
                                          .toInt(),
                                );
                                _seekTo(position);
                                setState(() {
                                  _isDragging = false;
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 2),
                            child: Text(
                              '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 全屏按钮
                    _buildControlButton(
                      icon: Icons.fullscreen,
                      onPressed: () {
                        // TODO: 实现全屏功能
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
