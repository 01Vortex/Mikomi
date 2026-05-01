import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/video_player_listener.dart';
import 'package:mikomi/features/video/ui/widgets/danmaku_overlay.dart';
import 'package:mikomi/features/video/ui/widgets/fullscreen/fullscreen_danmaku_settings.dart';
import 'package:mikomi/features/video/ui/widgets/fullscreen/fullscreen_episode.dart';
import 'package:mikomi/features/video/ui/widgets/video_fit.dart';
import 'package:mikomi/features/video/ui/widgets/video_gesture.dart';

// 顶部/底部控制栏统一左右边距（不含安全区），确保两侧完全对齐
const double _kSideMargin = 16.0;

class FullscreenVideoControls extends StatefulWidget {
  final VideoPlaybackService playbackService;
  final ValueListenable<VideoPlayerSnapshot> playerSnapshotListenable;
  final DanmakuConfig danmakuConfig;
  final bool isDanmakuInputVisible;
  final ValueChanged<bool>? onDanmakuInputVisibleChanged;
  final ValueChanged<double>? onPlaybackSpeedChanged;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onPlayPause;
  final ValueChanged<DanmakuConfig>? onDanmakuConfigChanged;
  final String title;
  final int currentEpisode;
  final String? currentSmallTitle;
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
  final void Function(bool)? onDanmakuToggle;
  final VideoFitMode fitMode;
  final ValueChanged<VideoFitMode>? onFitModeChanged;

  const FullscreenVideoControls({
    super.key,
    required this.playbackService,
    required this.playerSnapshotListenable,
    required this.danmakuConfig,
    this.isDanmakuInputVisible = false,
    this.onDanmakuInputVisibleChanged,
    this.onPlaybackSpeedChanged,
    this.onSeek,
    this.onPlayPause,
    this.onDanmakuConfigChanged,
    required this.title,
    required this.currentEpisode,
    this.currentSmallTitle,
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
    this.onDanmakuToggle,
    this.fitMode = VideoFitMode.contain,
    this.onFitModeChanged,
  });

  @override
  State<FullscreenVideoControls> createState() =>
      _FullscreenVideoControlsState();
}

class _FullscreenVideoControlsState extends State<FullscreenVideoControls> {
  bool _showControls = true;
  Duration _dragPosition = Duration.zero;
  bool _isDragging = false;
  bool _isLocked = false;
  Timer? _hideTimer;
  final TextEditingController _danmakuInputController = TextEditingController();
  final GlobalKey _speedButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _danmakuInputController.dispose();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    if (widget.playerSnapshotListenable.value.isPlaying && !_isLocked) {
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
    widget.onPlayPause?.call();
    _startHideTimer();
  }

  void _playPreviousEpisode() {
    widget.onPreviousEpisode?.call();
  }

  void _playNextEpisode() {
    widget.onNextEpisode?.call();
  }

  void _showSpeedSelector() {
    final RenderBox? renderBox =
        _speedButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // 使用全局坐标，确保全屏横屏下定位准确
    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    showMenu(
      context: context,
      useRootNavigator: true,
      position: RelativeRect.fromLTRB(
        buttonPosition.dx - (100 - buttonSize.width) / 2 - 4,
        buttonPosition.dy - 268 - 8,
        buttonPosition.dx + buttonSize.width + (100 - buttonSize.width) / 2 + 4,
        buttonPosition.dy - 8,
      ),
      color: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                color:
                    widget.playerSnapshotListenable.value.playbackSpeed == speed
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black87,
                fontSize: 15,
                fontWeight:
                    widget.playerSnapshotListenable.value.playbackSpeed == speed
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) {
        widget.onPlaybackSpeedChanged?.call(value);
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
    return formatVideoDuration(duration);
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).viewPadding;
    // 全屏横屏时安全区左右不对称（刘海/摄像头），直接用固定边距保证两侧完全对称
    const double leftPad = _kSideMargin;
    const double rightPad = _kSideMargin;

    return ValueListenableBuilder<VideoPlayerSnapshot>(
      valueListenable: widget.playerSnapshotListenable,
      builder: (context, snapshot, _) {
        final currentPosition = _isDragging ? _dragPosition : snapshot.position;
        return VideoGesture(
          playbackService: widget.playbackService,
          enabled: !_showControls && !_isLocked,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleControls,
                  behavior: HitTestBehavior.opaque,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
              if (snapshot.isBuffering) _buildBufferingIndicator(),
              if (_showControls && !_isLocked)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
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
              if (_showControls && !_isLocked)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
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
              if (_showControls && !_isLocked)
                _buildTopBar(
                  safePadding: safePadding,
                  leftPad: leftPad,
                  rightPad: rightPad,
                ),
              if (_showControls && !_isLocked)
                _buildCenterControls(isPlaying: snapshot.isPlaying),
              if (_showControls && !_isLocked)
                _buildBottomControls(
                  safePadding: safePadding,
                  leftPad: leftPad,
                  rightPad: rightPad,
                  isPlaying: snapshot.isPlaying,
                  position: currentPosition,
                  duration: snapshot.duration,
                  playbackSpeed: snapshot.playbackSpeed,
                ),
              _buildLockButton(),
            ],
          ),
        );
      },
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
          safePadding.top + 20,
          rightPad,
          10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 返回按钮：GestureDetector 不添加额外尺寸
            GestureDetector(
              onTap: widget.onExitFullscreen,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 28,
                height: 28,
                child: Icon(Icons.arrow_back, color: Colors.white, size: 28),
              ),
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.currentSmallTitle != null &&
                      widget.currentSmallTitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '第${widget.currentEpisode}集 ${widget.currentSmallTitle}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            // 更多按钮：与返回按钮等宽等高，确保两侧图标到屏幕边缘距离相同
            GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: Icon(Icons.more_vert, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls({required bool isPlaying}) {
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
            isPlaying ? Icons.pause : Icons.play_arrow,
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
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    required double playbackSpeed,
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
                  _formatDuration(position),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      trackShape: const RectangularSliderTrackShape(),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: Theme.of(context).colorScheme.primary,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                      thumbColor: Theme.of(context).colorScheme.primary,
                    ),
                    child: Slider(
                      value: duration.inMilliseconds > 0
                          ? (position.inMilliseconds / duration.inMilliseconds)
                                .clamp(0.0, 1.0)
                          : 0.0,
                      onChangeStart: (_) => _hideTimer?.cancel(),
                      onChanged: (value) {
                        setState(() {
                          _isDragging = true;
                          _dragPosition = Duration(
                            milliseconds: (value * duration.inMilliseconds)
                                .toInt(),
                          );
                        });
                      },
                      onChangeEnd: (value) {
                        setState(() => _isDragging = false);
                        widget.onSeek?.call(_dragPosition);
                        _startHideTimer();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDuration(duration),
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
                        _buildIconBtn(
                          Icons.skip_previous,
                          _playPreviousEpisode,
                        ),
                        const SizedBox(width: 10),
                        _buildIconBtn(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          _togglePlayPause,
                        ),
                        const SizedBox(width: 10),
                        _buildIconBtn(Icons.skip_next, _playNextEpisode),
                        const SizedBox(width: 20),
                        _buildDanmakuButton(),
                        const SizedBox(width: 10),
                        _buildDanmakuSettingButton(),
                        if (widget.isDanmakuInputVisible) ...[
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
                      child: _buildTextBtn(
                        '${playbackSpeed}x',
                        _showSpeedSelector,
                      ),
                    ),
                    const SizedBox(width: 16),
                    VideoFitButton(
                      fitMode: widget.fitMode,
                      onChanged: (mode) {
                        widget.onFitModeChanged?.call(mode);
                        _startHideTimer();
                      },
                    ),
                    const SizedBox(width: 16),
                    _buildIconBtn(
                      Icons.video_library_outlined,
                      _showEpisodeSelector,
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: widget.onExitFullscreen,
                      child: const Icon(
                        Icons.fullscreen_exit,
                        color: Colors.white,
                        size: 22,
                      ),
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
        final nextEnabled = !widget.isDanmakuEnabled;
        widget.onDanmakuToggle?.call(nextEnabled);
        widget.onDanmakuInputVisibleChanged?.call(nextEnabled);
        if (!nextEnabled) {
          _danmakuInputController.clear();
        }
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
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: DanmakuSettingsSidePanel(
              initialConfig: widget.danmakuConfig,
              onConfigChanged: widget.onDanmakuConfigChanged,
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
      controller: _danmakuInputController,
      onSend: _submitLocalDanmaku,
    );
  }

  void _submitLocalDanmaku() {
    final text = _danmakuInputController.text.trim();
    if (text.isEmpty) return;

    _danmakuInputController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已发送（本地回显）'),
        duration: Duration(seconds: 1),
      ),
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
