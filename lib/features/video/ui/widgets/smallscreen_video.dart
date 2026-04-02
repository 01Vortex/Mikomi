import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/services/danmaku_service.dart';
import 'package:mikomi/features/video/services/danmaku_broadcaster_service.dart';
import 'package:mikomi/features/video/ui/pages/fullscreen_video_page.dart';
import 'package:mikomi/features/video/ui/widgets/video_gesture.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/settings/video_play/service/play_setting_service.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';

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
  final void Function(bool)? onDanmakuToggle;

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
    this.onDanmakuToggle,
  });

  @override
  State<SmallscreenVideo> createState() => _SmallscreenVideoState();
}

class _SmallscreenVideoState extends State<SmallscreenVideo> {
  // 全屏页动态状态 notifier
  late final ValueNotifier<FullscreenVideoState> _fullscreenNotifier;

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
  int _lastLoadedEpisode = -1;
  bool _isDanmakuLoading = false;

  // 手势控制相关(预留)
  Timer? _hideVolumeUITimer;
  Timer? _hideBrightnessUITimer;

  // 双击控制
  int _doubleTapCount = 0;
  Timer? _doubleTapTimer;

  // 弹幕控制
  final DanmakuService _danmakuController = DanmakuService();
  final DanmakuBroadcasterService _danmakuBroadcasterService = DanmakuBroadcasterService();
  int _lastDanmakuSecond = -1;
  DanmakuController? _canvasController;
  StreamSubscription<bool>? _bufferingSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _completedSub;
  final PlaySettingsService _playSettingsService = PlaySettingsService();
  DanmakuConfig _danmakuConfig = const DanmakuConfig();

  @override
  void initState() {
    super.initState();
    _loadDanmakuConfig();
    _fullscreenNotifier = ValueNotifier(FullscreenVideoState(
      currentEpisode: widget.currentEpisode,
      episodes: widget.episodes,
      isLoadingEpisodes: widget.isLoadingEpisodes,
      isDescending: widget.isDescending,
      hasNextEpisode: widget.hasNextEpisode,
      hasPreviousEpisode: widget.hasPreviousEpisode,
      episodeTitle: widget.episodeTitle,
      isDanmakuEnabled: widget.isDanmakuEnabled,
      danmakuController: _canvasController,
      danmakuBroadcasterService: _danmakuBroadcasterService,
    ));
    _initPlayer();
    _startControlsTimer();
    _loadDanmaku();
  }

  @override
  void didUpdateWidget(SmallscreenVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fullscreenNotifier.value = FullscreenVideoState(
          currentEpisode: widget.currentEpisode,
          episodes: widget.episodes,
          isLoadingEpisodes: widget.isLoadingEpisodes,
          isDescending: widget.isDescending,
          hasNextEpisode: widget.hasNextEpisode,
          hasPreviousEpisode: widget.hasPreviousEpisode,
          episodeTitle: widget.episodeTitle,
          isDanmakuEnabled: widget.isDanmakuEnabled,
          danmakuController: _canvasController,
          danmakuBroadcasterService: _danmakuBroadcasterService,
        );
      }
    });

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

  void _cancelPlayerSubscriptions() {
    _bufferingSub?.cancel();
    _playingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completedSub?.cancel();
    _bufferingSub = null;
    _playingSub = null;
    _positionSub = null;
    _durationSub = null;
    _completedSub = null;
  }

  @override
  void dispose() {
    _cancelPlayerSubscriptions();
    _danmakuBroadcasterService.clear();
    _fullscreenNotifier.dispose();
    _hideTimer?.cancel();
    _hideVolumeUITimer?.cancel();
    _hideBrightnessUITimer?.cancel();
    _doubleTapTimer?.cancel();
    _danmakuController.dispose();
    super.dispose();
  }

  Future<void> _loadDanmakuConfig() async {
    final config = await DanmakuSettingService.loadAll();
    if (!mounted) return;
    setState(() => _danmakuConfig = config);
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

    if (_isDanmakuLoading) return;
    if (_lastLoadedEpisode == widget.currentEpisode &&
        _danmakuController.isLoaded) {
      return;
    }

    _isDanmakuLoading = true;
    bool loaded = false;

    if (widget.bangumiId != null) {
      loaded = await _danmakuController.loadDanmakuByBangumiId(
        widget.bangumiId!,
        widget.currentEpisode,
        fallbackTitle: widget.animeTitle,
      );
    } else if (widget.animeTitle != null) {
      loaded = await _danmakuController.loadDanmakuByTitle(
        widget.animeTitle!,
        widget.currentEpisode,
      );
    } else {
      debugPrint('没有番剧ID或标题,无法加载弹幕');
    }

    _isDanmakuLoading = false;
    _lastLoadedEpisode = widget.currentEpisode;

    if (mounted && !loaded) {
      final message = _danmakuController.lastError ?? '弹幕加载失败';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    }

    debugPrint('弹幕加载完成,已加载: ${_danmakuController.isLoaded}');
    debugPrint('弹幕数据量: ${_danmakuController.danmakuMap.length} 秒');
    debugPrint('==================================');
  }

  void _sendDanmakuAtTime(int second) {
    if (!widget.isDanmakuEnabled || !_danmakuController.isLoaded) {
      return;
    }
    final danmakus = _danmakuController.getDanmakuAtTime(second);
    _danmakuBroadcasterService.send(danmakus);
  }

  void _sendDanmakuWindow(int second) {
    _sendDanmakuAtTime(second - 1);
    _sendDanmakuAtTime(second);
    _sendDanmakuAtTime(second + 1);
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
      await widget.playerController.initialize(smallScreen: true);

      if (mounted && widget.videoUrl.isNotEmpty) {
        await widget.playerController.play(widget.videoUrl);

        final player = widget.playerController.player;
        if (player != null) {
          _cancelPlayerSubscriptions();
          _bufferingSub = player.stream.buffering.listen((buffering) {
            if (mounted) {
              setState(() {
                _isBuffering = buffering;
              });
            }
          });

          _playingSub = player.stream.playing.listen((playing) {
            if (mounted) {
              setState(() {
                _isPlaying = playing;
              });
            }
          });

          _positionSub = player.stream.position.listen((position) {
            if (mounted && !_isDragging) {
              setState(() {
                _currentPosition = position;
              });

              // 发送弹幕
              if (widget.isDanmakuEnabled && _isPlaying) {
                final currentSecond = position.inSeconds;
                if ((currentSecond - _lastDanmakuSecond).abs() > 2) {
                  _lastDanmakuSecond = currentSecond;
                  _sendDanmakuWindow(currentSecond);
                } else if (currentSecond != _lastDanmakuSecond) {
                  _lastDanmakuSecond = currentSecond;
                  _sendDanmakuAtTime(currentSecond);
                }
              }
            }
          });

          _durationSub = player.stream.duration.listen((duration) {
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

          _completedSub = player.stream.completed.listen((completed) async {
            if (!completed || !mounted) return;
            // 确认进度接近结尾才触发(避免误触)
            final pos = player.state.position.inSeconds;
            final dur = player.state.duration.inSeconds;
            if (dur <= 0 || pos < dur - 3) return;
            final autoPlayNext =
                await _playSettingsService.getAutoPlayNext();
            if (autoPlayNext && widget.hasNextEpisode) {
              widget.onNextEpisode?.call();
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
    // 记录进入全屏时的弹幕开关状态
    final danmakuEnabledBeforeFullscreen = widget.isDanmakuEnabled;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullscreenVideoPage(
              playerController: widget.playerController,
              title: widget.title,
              stateNotifier: _fullscreenNotifier,
              onNextEpisode: widget.onNextEpisode,
              onPreviousEpisode: widget.onPreviousEpisode,
              onEpisodeSelected: widget.onEpisodeSelected,
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
    ).then((_) {
      // 退出全屏后同步弹幕开关状态到父组件
      final danmakuEnabledAfterFullscreen =
          _fullscreenNotifier.value.isDanmakuEnabled;
      if (danmakuEnabledAfterFullscreen != danmakuEnabledBeforeFullscreen) {
        widget.onDanmakuToggle?.call(danmakuEnabledAfterFullscreen);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.playerController.videoController;
    final bool showPlayer = _errorMessage == null &&
        !_isLoading &&
        widget.playerController.isInitialized &&
        controller != null;

    return VideoGesture(
      playerController: widget.playerController,
      enabled: showPlayer && !_lockPanel,
      child: GestureDetector(
        onTap: showPlayer ? _handleTap : null,
        onDoubleTap: showPlayer ? _handleDoubleTap : null,
      child: Stack(
        children: [
          // 背景
          Positioned.fill(child: Container(color: Colors.black)),

          // 视频播放器（仅在就绪时显示）
          if (showPlayer)
            Positioned.fill(
              child: Video(
                controller: controller,
                controls: NoVideoControls,
                fit: BoxFit.contain,
              ),
            ),

          // 弹幕层
          if (showPlayer && widget.isDanmakuEnabled)
            Positioned.fill(
              child: DanmakuLayer(
                onControllerCreated: (controller) {
                  _canvasController = controller;
                  _danmakuBroadcasterService.register(controller);
                  // 同步弹幕 broadcaster 到全屏状态
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _fullscreenNotifier.value = FullscreenVideoState(
                      currentEpisode: _fullscreenNotifier.value.currentEpisode,
                      episodes: _fullscreenNotifier.value.episodes,
                      isLoadingEpisodes: _fullscreenNotifier.value.isLoadingEpisodes,
                      isDescending: _fullscreenNotifier.value.isDescending,
                      hasNextEpisode: _fullscreenNotifier.value.hasNextEpisode,
                      hasPreviousEpisode: _fullscreenNotifier.value.hasPreviousEpisode,
                      episodeTitle: _fullscreenNotifier.value.episodeTitle,
                      isDanmakuEnabled: _fullscreenNotifier.value.isDanmakuEnabled,
                      danmakuController: controller,
                      danmakuBroadcasterService: _danmakuBroadcasterService,
                    );
                  });
                },
                fontSize: _danmakuConfig.fontSize,
                opacity: _danmakuConfig.opacity,
                speed: _danmakuConfig.duration,
                area: _danmakuConfig.area,
                strokeWidth: _danmakuConfig.strokeWidth,
                hideTop: !_danmakuConfig.showTop,
                hideBottom: !_danmakuConfig.showBottom,
                hideScroll: !_danmakuConfig.showScroll,
              ),
            ),

          // 加载中
          if (_isLoading)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),

          // 错误信息
          if (_errorMessage != null)
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.white70,
                      size: 48,
                    ),
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
                    TextButton(
                      onPressed: _initPlayer,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),

          // 缓冲指示器
          if (showPlayer && _isBuffering) _buildBufferingIndicator(),

          // 顶部渐变遮罩（播放中且显示控制栏时）
          if (showPlayer && _showControls && !_lockPanel) _buildTopGradient(),

          // 底部渐变遮罩
          if (showPlayer && _showControls && !_lockPanel) _buildBottomGradient(),

          // 顶部控制栏：播放中跟随控制栏显隐；加载/错误时始终显示
          if (!showPlayer || (_showControls && !_lockPanel))
            _buildTopControls(),

          // 底部控制栏（仅播放中显示）
          if (showPlayer && _showControls && !_lockPanel) _buildBottomControls(),

          // 锁定按钮
          if (showPlayer) _buildLockButton(),
        ],
      ),
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
        padding: const EdgeInsets.only(left: 8, right: 4, top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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

/// 全屏页动态状态数据
class FullscreenVideoState {
  final int currentEpisode;
  final List<Episode> episodes;
  final bool isLoadingEpisodes;
  final bool isDescending;
  final bool hasNextEpisode;
  final bool hasPreviousEpisode;
  final String? episodeTitle;
  final bool isDanmakuEnabled;
  final DanmakuController? danmakuController;
  final DanmakuBroadcasterService? danmakuBroadcasterService;

  const FullscreenVideoState({
    required this.currentEpisode,
    required this.episodes,
    required this.isLoadingEpisodes,
    required this.isDescending,
    required this.hasNextEpisode,
    required this.hasPreviousEpisode,
    this.episodeTitle,
    this.isDanmakuEnabled = false,
    this.danmakuController,
    this.danmakuBroadcasterService,
  });
}
