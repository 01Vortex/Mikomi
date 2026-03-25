import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/ui/widgets/fullscreen_episode.dart';
import 'package:mikomi/core/models/episode.dart';

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
  bool _isDanmakuEnabled = false;
  bool _showDanmakuInput = false;
  final TextEditingController _danmakuController = TextEditingController();
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _bufferingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
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
    }
  }

  void _cancelPlayerSubscriptions() {
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub = null;
    _bufferingSub = null;
    _positionSub = null;
    _durationSub = null;
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
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
            child: FullscreenEpisodeSelector(
              episodes: widget.episodes,
              currentEpisode: widget.currentEpisode,
              onEpisodeSelected: (episode) {
                if (widget.onEpisodeSelected != null) {
                  widget.onEpisodeSelected!(episode);
                }
              },
              isLoading: widget.isLoadingEpisodes,
              isDescending: widget.isDescending,
              onToggleSort: widget.onToggleSort ?? () {},
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
    return Stack(
      children: [
        // 主内容区域 - 可以点击切换控制栏
        Positioned.fill(
          child: GestureDetector(
            onTap: _toggleControls,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),

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
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  // TODO: 打开设置面板
                },
              ),
            ],
          ),
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

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 进度条
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: Row(
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
                          activeTrackColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          inactiveTrackColor: Colors.white.withValues(
                            alpha: 0.3,
                          ),
                          thumbColor: Theme.of(context).colorScheme.primary,
                        ),
                        child: Slider(
                          value: _duration.inMilliseconds > 0
                              ? (_position.inMilliseconds /
                                        _duration.inMilliseconds)
                                    .clamp(0.0, 1.0)
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
                            setState(() => _isDragging = false);
                            widget.playerController.player?.seek(_position);
                            _startHideTimer();
                          },
                          onChangeStart: (value) {
                            _hideTimer?.cancel();
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
              ),
              const SizedBox(height: 8),
              // 底部按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 左侧按钮组
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (widget.hasPreviousEpisode)
                            _buildBottomButton(
                              icon: Icons.skip_previous,
                              label: '上一集',
                              onTap: widget.onPreviousEpisode ?? () {},
                              iconOnly: true,
                            ),
                          if (widget.hasPreviousEpisode)
                            const SizedBox(width: 12),
                          _buildBottomButton(
                            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
                            label: _isPlaying ? '暂停' : '播放',
                            onTap: _togglePlayPause,
                            iconOnly: true,
                          ),
                          if (widget.hasNextEpisode) ...[
                            const SizedBox(width: 12),
                            _buildBottomButton(
                              icon: Icons.skip_next,
                              label: '下一集',
                              onTap: widget.onNextEpisode ?? () {},
                              iconOnly: true,
                            ),
                          ],
                          const SizedBox(width: 24),
                          _buildDanmakuButton(),
                          const SizedBox(width: 12),
                          _buildDanmakuSettingButton(),
                          if (_showDanmakuInput) ...[
                            const SizedBox(width: 12),
                            _buildDanmakuInputInline(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 右侧按钮组
                  Row(
                    children: [
                      Container(
                        key: _speedButtonKey,
                        child: _buildBottomButton(
                          icon: Icons.speed,
                          label: '${_playbackSpeed}x',
                          onTap: _showSpeedSelector,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildBottomButton(
                        icon: Icons.playlist_play,
                        label: '选集',
                        onTap: _showEpisodeSelector,
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
    bool iconOnly = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: iconOnly
            ? const EdgeInsets.all(8)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(iconOnly ? 8 : 16),
        ),
        child: iconOnly
            ? Icon(icon, color: Colors.white, size: 20)
            : Row(
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

  Widget _buildDanmakuButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isDanmakuEnabled = !_isDanmakuEnabled;
          if (_isDanmakuEnabled) {
            _showDanmakuInput = true;
          } else {
            _showDanmakuInput = false;
            _danmakuController.clear();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SvgPicture.asset(
          _isDanmakuEnabled
              ? 'assets/icons/danmaku_on.svg'
              : 'assets/icons/danmaku_off.svg',
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }

  Widget _buildDanmakuSettingButton() {
    return GestureDetector(
      onTap: () {
        // TODO: 打开弹幕设置面板
      },
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
    final inputWidth =
        (MediaQuery.sizeOf(context).width * 0.3).clamp(120.0, 220.0).toDouble();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: inputWidth,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _danmakuController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: const InputDecoration(
              hintText: '发个友善的弹幕见证当下',
              hintStyle: TextStyle(color: Colors.white60, fontSize: 13),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onSubmitted: (value) {
              _submitLocalDanmaku();
            },
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _submitLocalDanmaku,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '发送',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
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
      right: 16,
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
