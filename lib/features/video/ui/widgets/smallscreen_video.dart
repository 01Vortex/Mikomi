import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/services/Bangumi_danmaku_service.dart';
import 'package:mikomi/features/video/ui/pages/fullscreen_video_page.dart';
import 'package:mikomi/core/models/episode.dart';

class SmallscreenVideo extends StatefulWidget {
  final String videoUrl;
  final String title;
  final int currentEpisode;
  final int totalEpisodes;
  final VideoPlaybackService playerController;
  final String? episodeTitle;
  final VoidCallback? onBack;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final bool hasNextEpisode;
  final bool hasPreviousEpisode;
  final Duration? initialProgress;
  final List<Episode> episodes;
  final Function(Episode)? onEpisodeSelected;
  final bool isLoadingEpisodes;
  final bool isDescending;
  final VoidCallback? onToggleSort;
  final bool isDanmakuEnabled;
  final String? animeTitle;
  final int? bangumiId;

  const SmallscreenVideo({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.currentEpisode,
    required this.totalEpisodes,
    required this.playerController,
    this.episodeTitle,
    this.onBack,
    this.onOpenMenu,
    this.onNextEpisode,
    this.onPreviousEpisode,
    this.hasNextEpisode = false,
    this.hasPreviousEpisode = false,
    this.initialProgress,
    this.episodes = const [],
    this.onEpisodeSelected,
    this.isLoadingEpisodes = false,
    this.isDescending = false,
    this.onToggleSort,
    this.isDanmakuEnabled = false,
    this.animeTitle,
    this.bangumiId,
  });

  @override
  State<SmallscreenVideo> createState() => _SmallscreenVideoState();
}

class _SmallscreenVideoState extends State<SmallscreenVideo> {
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
  bool _hasRestoredProgress = false; // 是否已恢复进度

  // 手势控制相关(预留)
  Timer? _hideVolumeUITimer;
  Timer? _hideBrightnessUITimer;

  // 双击控制
  int _doubleTapCount = 0;
  Timer? _doubleTapTimer;

  // 弹幕控制
  final BangumiDanmakuService _danmakuController = BangumiDanmakuService();
  int _lastDanmakuSecond = -1;
  DanmakuController? _canvasController;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _startControlsTimer();
    _loadDanmaku();
  }

  @override
  void didUpdateWidget(SmallscreenVideo oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 监听弹幕开关变化
    if (oldWidget.isDanmakuEnabled != widget.isDanmakuEnabled) {
      debugPrint(
        '弹幕开关状态变化: ${oldWidget.isDanmakuEnabled} -> ${widget.isDanmakuEnabled}',
      );
      if (widget.isDanmakuEnabled && !_danmakuController.isLoaded) {
        _loadDanmaku();
      }
    }

    // 监听集数变化
    if (oldWidget.currentEpisode != widget.currentEpisode) {
      debugPrint(
        '集数变化: ${oldWidget.currentEpisode} -> ${widget.currentEpisode}',
      );
      if (widget.isDanmakuEnabled) {
        _loadDanmaku();
      }
    }

    // 只有在URL真正变化时才重新初始化播放器
    if (oldWidget.videoUrl != widget.videoUrl && widget.videoUrl.isNotEmpty) {
      debugPrint('视频URL变化: ${oldWidget.videoUrl} -> ${widget.videoUrl}');
      _hasRestoredProgress = false;
      _initPlayer();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _hideVolumeUITimer?.cancel();
    _hideBrightnessUITimer?.cancel();
    _doubleTapTimer?.cancel();
    _danmakuController.dispose();
    super.dispose();
  }

  Future<void> _loadDanmaku() async {
    debugPrint('========== 开始加载弹幕 ==========');
    debugPrint('弹幕开关状态: ${widget.isDanmakuEnabled}');
    debugPrint('番剧ID: ${widget.bangumiId}');
    debugPrint('番剧标题: ${widget.animeTitle}');
    debugPrint('当前集数: ${widget.currentEpisode}');

    if (!widget.isDanmakuEnabled) {
      debugPrint('弹幕未开启,跳过加载');
      debugPrint('==================================');
      return;
    }

    if (widget.bangumiId != null) {
      await _danmakuController.loadDanmakuByBangumiId(
        widget.bangumiId!,
        widget.currentEpisode,
        fallbackTitle: widget.animeTitle,
      );
    } else if (widget.animeTitle != null) {
      await _danmakuController.loadDanmakuByTitle(
        widget.animeTitle!,
        widget.currentEpisode,
      );
    } else {
      debugPrint('没有番剧ID或标题,无法加载弹幕');
    }

    debugPrint('弹幕加载完成,已加载: ${_danmakuController.isLoaded}');
    debugPrint('弹幕数据量: ${_danmakuController.danmakuMap.length} 秒');
    debugPrint('==================================');
  }

  void _sendDanmakuAtTime(int second) {
    if (!widget.isDanmakuEnabled ||
        !_danmakuController.isLoaded ||
        _canvasController == null) {
      return;
    }

    final danmakus = _danmakuController.getDanmakuAtTime(second);
    if (danmakus.isNotEmpty) {
      debugPrint('发送 ${danmakus.length} 条弹幕 (时间: ${second}s)');
    }

    for (var danmaku in danmakus) {
      _canvasController!.addDanmaku(
        DanmakuContentItem(
          danmaku.message,
          color: danmaku.color,
          type: danmaku.type == 5
              ? DanmakuItemType.top
              : (danmaku.type == 4
                    ? DanmakuItemType.bottom
                    : DanmakuItemType.scroll),
        ),
      );
    }
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

              // 发送弹幕
              if (widget.isDanmakuEnabled && _isPlaying) {
                final currentSecond = position.inSeconds;
                if (currentSecond != _lastDanmakuSecond) {
                  _lastDanmakuSecond = currentSecond;
                  _sendDanmakuAtTime(currentSecond);
                }
              }
            }
          });

          player.stream.duration.listen((duration) {
            if (mounted) {
              setState(() {
                _totalDuration = duration;
              });

              // 当视频时长加载完成后,跳转到初始进度(只执行一次)
              if (!_hasRestoredProgress &&
                  widget.initialProgress != null &&
                  widget.initialProgress!.inSeconds > 0 &&
                  duration.inSeconds > 0) {
                _hasRestoredProgress = true;
                debugPrint('========== 恢复播放进度 ==========');
                debugPrint('目标进度: ${widget.initialProgress!.inSeconds}秒');
                debugPrint('视频总时长: ${duration.inSeconds}秒');
                debugPrint('==================================');

                // 延迟一小段时间再跳转,确保播放器完全准备好
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted &&
                      player.state.duration.inSeconds > 0 &&
                      widget.initialProgress!.inSeconds <
                          player.state.duration.inSeconds) {
                    player.seek(widget.initialProgress!);
                    debugPrint('进度恢复成功');
                  }
                });
              }
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

  void _enterFullscreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullscreenVideoPage(
              playerController: widget.playerController,
              title: widget.title,
              currentEpisode: widget.currentEpisode,
              episodeTitle: widget.episodeTitle,
              onNextEpisode: widget.onNextEpisode,
              onPreviousEpisode: widget.onPreviousEpisode,
              hasNextEpisode: widget.hasNextEpisode,
              hasPreviousEpisode: widget.hasPreviousEpisode,
              episodes: widget.episodes,
              onEpisodeSelected: widget.onEpisodeSelected,
              isLoadingEpisodes: widget.isLoadingEpisodes,
              isDescending: widget.isDescending,
              onToggleSort: widget.onToggleSort,
            ),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          );

          return FadeTransition(opacity: curvedAnimation, child: child);
        },
      ),
    );
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

          // 弹幕层
          if (widget.isDanmakuEnabled)
            Positioned.fill(
              child: IgnorePointer(
                child: DanmakuScreen(
                  createdController: (controller) {
                    _canvasController = controller;
                  },
                  option: DanmakuOption(
                    fontSize: 16,
                    opacity: 1.0,
                    duration: 8,
                    strokeWidth: 1.0,
                    area: 0.5,
                  ),
                ),
              ),
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
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {
                // TODO: 显示设置菜单
                debugPrint('打开播放器设置');
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              iconSize: 24,
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
              onPressed: _enterFullscreen,
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
