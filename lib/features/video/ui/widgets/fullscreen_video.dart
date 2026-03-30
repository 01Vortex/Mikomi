import 'dart:async';
import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_settings_sheet.dart';
import 'package:mikomi/features/video/ui/widgets/fullscreen_episode.dart';
import 'package:mikomi/features/video/ui/widgets/video_gesture_detector.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:mikomi/features/settings/video_play/service/play_setting_service.dart';

// 顶部/底部控制栏统一左右边距（不含安全区），确保两侧完全对齐
const double _kSideMargin = 16.0;

class FullscreenVideoControls extends StatefulWidget {
  final VideoPlaybackService playerController;
  final String title;
  final int currentEpisode;
  final String? episodeTitle;
  final VoidCallback onExitFullscreen;
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
  final DanmakuController? danmakuController;
  final void Function(bool)? onDanmakuToggle;

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
    this.episodes = const [],
    this.onEpisodeSelected,
    this.isLoadingEpisodes = false,
    this.isDescending = false,
    this.onToggleSort,
    this.isDanmakuEnabled = false,
    this.danmakuController,
    this.onDanmakuToggle,
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
  bool _showDanmakuInput = false;
  final TextEditingController _danmakuController = TextEditingController();
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _bufferingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _completedSub;
  final PlaySettingsService _playSettingsService = PlaySettingsService();
  final GlobalKey _speedButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializePlayerState();
    _setupListeners();
    _startHideTimer();
  }

  void _initializePlayerState() {
    final player = widget.playerController.player;
    if (player != null) {
      // 获取播放器当前状态
      _isPlaying = player.state.playing;
      _position = player.state.position;
      _duration = player.state.duration;
      _isBuffering = player.state.buffering;
      _playbackSpeed = player.state.rate;
    }
  }

  void _cancelPlayerSubscriptions() {
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completedSub?.cancel();
    _playingSub = null;
    _bufferingSub = null;
    _positionSub = null;
    _durationSub = null;
    _completedSub = null;
  }

  @override
  void dispose() {
    _cancelPlayerSubscriptions();
    _hideTimer?.cancel();
    _danmakuController.dispose();
    super.dispose();
  }

  void _setupListeners() {
    final player = widget.playerController.player;
    if (player == null) return;

    _cancelPlayerSubscriptions();

    _playingSub = player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });

    _bufferingSub = player.stream.buffering.listen((buffering) {
      if (mounted) {
        setState(() => _isBuffering = buffering);
      }
    });

    _positionSub = player.stream.position.listen((position) {
      if (mounted && !_isDragging) {
        setState(() => _position = position);
      }
    });

    _durationSub = player.stream.duration.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    player.stream.rate.listen((rate) {
      if (mounted) {
        setState(() => _playbackSpeed = rate);
      }
    });

    _completedSub = player.stream.completed.listen((completed) async {
      if (!completed || !mounted) return;
      // 确认进度接近结尾才触发(避免误触)
      final pos = player.state.position.inSeconds;
      final dur = player.state.duration.inSeconds;
      if (dur <= 0 || pos < dur - 3) return;
      final autoPlayNext = await _playSettingsService.getAutoPlayNext();
      if (autoPlayNext && widget.hasNextEpisode) {
        widget.onNextEpisode?.call();
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

  void _playPreviousEpisode() {
    if (widget.episodes.isEmpty) {
      widget.onPreviousEpisode?.call();
      return;
    }
    if (widget.hasPreviousEpisode) {
      widget.onPreviousEpisode?.call();
    } else {
      // 第一集 → 跳到最后一集
      final last = widget.episodes.last;
      widget.onEpisodeSelected?.call(last);
    }
  }

  void _playNextEpisode() {
    if (widget.episodes.isEmpty) {
      widget.onNextEpisode?.call();
      return;
    }
    if (widget.hasNextEpisode) {
      widget.onNextEpisode?.call();
    } else {
      // 最后一集 → 跳到第一集
      final first = widget.episodes.first;
      widget.onEpisodeSelected?.call(first);
    }
  }

  void _showSpeedSelector() {
    final RenderBox? renderBox =
        _speedButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final buttonPosition = renderBox.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );
    final buttonSize = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx,
        buttonPosition.dy - 280,
        buttonPosition.dx + buttonSize.width,
        buttonPosition.dy,
      ),
      color: Colors.black.withValues(alpha: 0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      constraints: const BoxConstraints(minWidth: 100, maxWidth: 100),
      items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
        return PopupMenuItem(
          value: speed,
          height: 42,
          padding: EdgeInsets.zero,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              '${speed}x',
              style: TextStyle(
                color: _playbackSpeed == speed
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
                fontSize: 15,
                fontWeight: _playbackSpeed == speed
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        setState(() => _playbackSpeed = value);
        widget.playerController.player?.setRate(value);
      }
    });
  }

  void _showEpisodeSelector() {
    final outerContext = context;
    bool isDescending = widget.isDescending;
    showGeneralDialog(
      context: outerContext,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return FullscreenEpisodeSelector(
                  episodes: widget.episodes,
                  currentEpisode: widget.currentEpisode,
                  onEpisodeSelected: (episode) {
                    Navigator.of(dialogContext).pop();
                    widget.onEpisodeSelected?.call(episode);
                  },
                  isLoading: widget.isLoadingEpisodes,
                  isDescending: isDescending,
                  onToggleSort: () {
                    setDialogState(() => isDescending = !isDescending);
                    widget.onToggleSort?.call();
                  },
                );
              },
            ),
          ),
        );
      },
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
    final safePadding = MediaQuery.of(context).viewPadding;
    final double leftPad = safePadding.left + _kSideMargin;
    final double rightPad = safePadding.right + _kSideMargin;

    return VideoGestureDetector(
      playerController: widget.playerController,
      child: Stack(
        children: [
          // 点击区域切换控制栏
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggleControls,
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),

          // 缓冲指示器
          if (_isBuffering) _buildBufferingIndicator(),

          // 顶部渐变遮罩
          if (_showControls && !_isLocked)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // 底部渐变遮罩
          if (_showControls && !_isLocked)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.72),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

          // 顶部控制栏
          if (_showControls && !_isLocked)
            _buildTopBar(safePadding: safePadding, leftPad: leftPad, rightPad: rightPad),

          // 中间播放/暂停
          if (_showControls && !_isLocked) _buildCenterControls(),

          // 底部控制栏
          if (_showControls && !_isLocked)
            _buildBottomControls(safePadding: safePadding, leftPad: leftPad, rightPad: rightPad),

          // 锁屏按钮
          _buildLockButton(),
        ],
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
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
    );
  }

  // 顶部控制栏：返回按钮左边距 = leftPad，更多按钮右边距 = rightPad，两侧完全对称
  Widget _buildTopBar({
    required EdgeInsets safePadding,
    required double leftPad,
    required double rightPad,
  }) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          leftPad,
          safePadding.top + 10,
          rightPad,
          10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: widget.onExitFullscreen,
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
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
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {},
              child: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Center(
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 38,
          ),
        ),
      ),
    );
  }

  // 底部控制栏：进度条和按钮组都使用 leftPad/rightPad，与顶部完全对齐
  Widget _buildBottomControls({
    required EdgeInsets safePadding,
    required double leftPad,
    required double rightPad,
  }) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          leftPad,
          0,
          rightPad,
          safePadding.bottom + 10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 进度条行：时间 + Slider + 时间
            Row(
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      trackShape: const RectangularSliderTrackShape(),
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                      thumbColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Slider(
                      value: _duration.inMilliseconds > 0
                          ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                          : 0.0,
                      onChangeStart: (_) => _hideTimer?.cancel(),
                      onChanged: (value) {
                        setState(() {
                          _isDragging = true;
                          _position = Duration(
                            milliseconds: (value * _duration.inMilliseconds).toInt(),
                          );
                        });
                      },
                      onChangeEnd: (value) {
                        setState(() => _isDragging = false);
                        widget.playerController.player?.seek(_position);
                        _startHideTimer();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 按钮行：左侧滚动组 + 右侧固定组
            Row(
              children: [
                // 左侧按钮组（可横向滚动）
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildIconBtn(Icons.skip_previous, _playPreviousEpisode),
                        const SizedBox(width: 10),
                        _buildIconBtn(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          _togglePlayPause,
                        ),
                        const SizedBox(width: 10),
                        _buildIconBtn(Icons.skip_next, _playNextEpisode),
                        const SizedBox(width: 20),
                        _buildDanmakuButton(),
                        const SizedBox(width: 10),
                        _buildDanmakuSettingButton(),
                        if (_showDanmakuInput) ...[  
                          const SizedBox(width: 10),
                          _buildDanmakuInputInline(),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 右侧按钮组
                Row(
                  children: [
                    KeyedSubtree(
                      key: _speedButtonKey,
                      child: _buildTextBtn('${_playbackSpeed}x', _showSpeedSelector),
                    ),
                    const SizedBox(width: 10),
                    _buildTextBtn('选集', _showEpisodeSelector),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: widget.onExitFullscreen,
                      child: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildTextBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  // 旧方法已由 _buildBottomControls({...}) 替代，此处占位已删除

  Widget _buildDanmakuButton() {
    return GestureDetector(
      onTap: () {
        final newEnabled = !widget.isDanmakuEnabled;
        setState(() {
          _showDanmakuInput = newEnabled;
          if (!newEnabled) _danmakuController.clear();
        });
        widget.onDanmakuToggle?.call(newEnabled);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SvgPicture.asset(
          widget.isDanmakuEnabled
              ? 'assets/icons/danmaku_on.svg'
              : 'assets/icons/danmaku_off.svg',
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }

  void _showDanmakuSettings() {
    final outerContext = context;
    showGeneralDialog(
      context: outerContext,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: DanmakuSettingsSidebar(
              onClose: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDanmakuSettingButton() {
    return GestureDetector(
      onTap: _showDanmakuSettings,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SvgPicture.asset(
          'assets/icons/danmaku_setting.svg',
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildDanmakuInputInline() {
    return DanmakuInlineInput(
      controller: _danmakuController,
      onSend: _submitLocalDanmaku,
    );
  }

  void _submitLocalDanmaku() {
    final text = _danmakuController.text.trim();
    if (text.isEmpty) return;

    _danmakuController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已发送（本地回显）'), duration: Duration(seconds: 1)),
    );
  }

  Widget _buildLockButton() {
    return Positioned(
      right: _kSideMargin,
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
