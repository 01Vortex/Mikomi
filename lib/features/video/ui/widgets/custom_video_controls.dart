import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

class CustomVideoControls extends StatefulWidget {
  final VideoController controller;
  final String title;
  final int currentEpisode;
  final String? episodeTitle;
  final VoidCallback? onDanmakuToggle;
  final VoidCallback? onDanmakuSend;
  final bool isDanmakuEnabled;

  const CustomVideoControls({
    super.key,
    required this.controller,
    required this.title,
    required this.currentEpisode,
    this.episodeTitle,
    this.onDanmakuToggle,
    this.onDanmakuSend,
    this.isDanmakuEnabled = false,
  });

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  bool _showControls = true;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    widget.controller.player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => _isPlaying = playing);
      }
    });

    widget.controller.player.stream.position.listen((position) {
      if (mounted && !_isDragging) {
        setState(() => _position = position);
      }
    });

    widget.controller.player.stream.duration.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });
  }

  void _togglePlayPause() {
    widget.controller.player.playOrPause();
  }

  void _seekForward() {
    final newPosition = _position + const Duration(seconds: 10);
    widget.controller.player.seek(
      newPosition > _duration ? _duration : newPosition,
    );
  }

  void _seekBackward() {
    final newPosition = _position - const Duration(seconds: 10);
    widget.controller.player.seek(
      newPosition < Duration.zero ? Duration.zero : newPosition,
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
      onTap: () {
        setState(() => _showControls = !_showControls);
      },
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // 顶部标题栏
            _buildTopBar(),
            // 中间播放/暂停按钮
            if (_showControls) _buildCenterControls(),
            // 右侧快捷按钮
            if (_showControls) _buildRightSideButtons(),
            // 底部控制栏
            if (_showControls) _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  // 顶部标题栏（保持不变）
  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            12,
            MediaQuery.of(context).padding.top + 8,
            12,
            16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
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
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 中间播放控制
  Widget _buildCenterControls() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildControlButton(icon: Icons.replay_10, onTap: _seekBackward),
          const SizedBox(width: 40),
          _buildControlButton(
            icon: _isPlaying ? Icons.pause : Icons.play_arrow,
            onTap: _togglePlayPause,
            size: 64,
          ),
          const SizedBox(width: 40),
          _buildControlButton(icon: Icons.forward_10, onTap: _seekForward),
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

  // 右侧快捷按钮
  Widget _buildRightSideButtons() {
    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.3,
      child: Column(
        children: [
          _buildSideButton(
            icon: Icons.camera_alt_outlined,
            label: '截图',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _buildSideButton(icon: Icons.lock_outline, label: '锁定', onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildSideButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // 底部控制栏
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
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
                    ),
                    child: Slider(
                      value: _duration.inMilliseconds > 0
                          ? _position.inMilliseconds / _duration.inMilliseconds
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
                        widget.controller.player.seek(_position);
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Colors.white.withValues(alpha: 0.3),
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
            const SizedBox(height: 12),
            // 底部按钮栏
            Row(
              children: [
                _buildBottomButton(
                  icon: Icons.skip_next,
                  label: '下一集',
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                if (widget.onDanmakuToggle != null)
                  _buildBottomButton(
                    icon: widget.isDanmakuEnabled
                        ? Icons.subtitles
                        : Icons.subtitles_off_outlined,
                    label: '弹幕',
                    onTap: widget.onDanmakuToggle!,
                  ),
                if (widget.onDanmakuSend != null) ...[
                  const SizedBox(width: 12),
                  Expanded(child: _buildDanmakuInput()),
                ],
                const Spacer(),
                _buildBottomButton(
                  icon: Icons.speed,
                  label: '倍速',
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _buildBottomButton(
                  icon: Icons.playlist_play,
                  label: '选集',
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _buildBottomButton(
                  icon: Icons.fullscreen,
                  label: '全屏',
                  onTap: () {},
                ),
              ],
            ),
          ],
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

  Widget _buildDanmakuInput() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: '发个友善的弹幕见证当下',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onDanmakuSend,
            child: Text(
              '发送',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
