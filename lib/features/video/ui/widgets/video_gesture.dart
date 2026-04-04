import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

class VideoGesture extends StatefulWidget {
  final Widget child;
  final VideoPlaybackService playbackService;
  final bool enabled;

  const VideoGesture({
    super.key,
    required this.child,
    required this.playbackService,
    this.enabled = true,
  });

  @override
  State<VideoGesture> createState() => _VideoGestureState();
}

enum _GestureType { none, brightness, volume, seek }

class _VideoGestureState extends State<VideoGesture>
    with TickerProviderStateMixin {
  _GestureType _gestureType = _GestureType.none;
  double _startDragY = 0;
  double _startDragX = 0;
  double _startValue = 0;
  double _startPosition = 0; // 拖动开始时的播放进度（秒）
  double _seekPosition = 0;  // 当前拖动目标进度（秒）
  double _totalDuration = 0;

  bool _showBrightnessHud = false;
  bool _showVolumeHud = false;
  bool _showSpeedHud = false;
  bool _showSeekHud = false;
  double _brightness = 0.5;
  double _volume = 0.5;
  double _normalSpeed = 1.0;
  bool _isLongPressing = false;
  bool _isDragging = false;
  bool _isAdjusting = false;

  // 节流：限制音量/亮度系统调用频率
  DateTime _lastSystemCall = DateTime(0);
  static const _throttleMs = 50;

  Timer? _hudHideTimer;

  // 加速脉冲动画
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 禁用系统音量UI，使用自定义HUD
    VolumeController().showSystemUI = false;
    VolumeController().listener((v) {
      // 拖动期间忽略系统回调，防止与手势计算互相抖动
      if (mounted && !_isAdjusting) setState(() => _volume = v);
    });
    VolumeController().getVolume().then((v) {
      if (mounted) setState(() => _volume = v);
    });
    ScreenBrightness().current.then((v) {
      if (mounted) setState(() => _brightness = v);
    });
  }

  @override
  void dispose() {
    // 恢复系统音量UI控制
    VolumeController().showSystemUI = true;
    VolumeController().removeListener();
    // 退出播放器时恢复系统亮度
    ScreenBrightness().resetScreenBrightness();
    _hudHideTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _showHud(_GestureType type) {
    setState(() {
      _showBrightnessHud = type == _GestureType.brightness;
      _showVolumeHud = type == _GestureType.volume;
      _showSeekHud = type == _GestureType.seek;
    });
  }

  void _scheduleHudHide() {
    _hudHideTimer?.cancel();
    _hudHideTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _showBrightnessHud = false;
          _showVolumeHud = false;
          _showSeekHud = false;
          _isDragging = false;
        });
      }
    });
  }

  bool _isLeftSide(Offset pos, BoxConstraints c) => pos.dx < c.maxWidth / 2;

  void _onHorizontalDragStart(DragStartDetails d, BoxConstraints c) {
    if (!widget.enabled) return;
    _startDragX = d.localPosition.dx;
    _isDragging = true;
    _gestureType = _GestureType.seek;
    final player = widget.playbackService.player;
    if (player != null) {
      _totalDuration = player.state.duration.inSeconds.toDouble();
      _startPosition = player.state.position.inSeconds.toDouble();
      _seekPosition = _startPosition;
    }
    HapticFeedback.selectionClick();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d, BoxConstraints c) {
    if (!widget.enabled || _gestureType != _GestureType.seek) return;
    if (_totalDuration <= 0) return;
    final dx = d.localPosition.dx - _startDragX;
    // 全屏宽度对应最多 90 秒快进/后退
    final delta = (dx / c.maxWidth) * 90.0;
    _seekPosition = (_startPosition + delta).clamp(0.0, _totalDuration);
    setState(() {});
    _showHud(_GestureType.seek);
  }

  void _onHorizontalDragEnd(DragEndDetails _) {
    if (_gestureType != _GestureType.seek) return;
    final player = widget.playbackService.player;
    if (player != null && _totalDuration > 0) {
      player.seek(Duration(seconds: _seekPosition.round()));
    }
    _gestureType = _GestureType.none;
    _scheduleHudHide();
  }

  void _onVerticalDragStart(DragStartDetails d, BoxConstraints c) {
    if (!widget.enabled) return;
    _startDragY = d.localPosition.dy;
    _isDragging = true;
    _isAdjusting = true;
    VolumeController().showSystemUI = false;
    final isLeft = _isLeftSide(d.localPosition, c);
    _gestureType = isLeft ? _GestureType.brightness : _GestureType.volume;
    HapticFeedback.selectionClick();
    _startValue = isLeft ? _brightness : _volume;
  }

  void _onVerticalDragUpdate(DragUpdateDetails d, BoxConstraints c) {
    if (!widget.enabled || _gestureType == _GestureType.none) return;
    final dy = _startDragY - d.localPosition.dy;
    final delta = dy / (c.maxHeight * 0.7);
    final newVal = (_startValue + delta).clamp(0.0, 1.0);
    // 节流：限制系统调用频率，避免卡顿
    final now = DateTime.now();
    final shouldCall = now.difference(_lastSystemCall).inMilliseconds >= _throttleMs;
    if (_gestureType == _GestureType.brightness) {
      setState(() => _brightness = newVal);
      if (shouldCall) {
        _lastSystemCall = now;
        ScreenBrightness().setScreenBrightness(newVal);
      }
      _showHud(_GestureType.brightness);
    } else {
      setState(() => _volume = newVal);
      if (shouldCall) {
        _lastSystemCall = now;
        VolumeController().setVolume(newVal, showSystemUI: false);
      }
      _showHud(_GestureType.volume);
    }
  }

  void _onVerticalDragEnd(DragEndDetails _) {
    _gestureType = _GestureType.none;
    _isAdjusting = false;
    _scheduleHudHide();
  }

  void _onLongPressStart(LongPressStartDetails _) {
    if (!widget.enabled) return;
    _isLongPressing = true;
    final player = widget.playbackService.player;
    if (player != null) {
      _normalSpeed = player.state.rate;
      player.setRate(2.0);
    }
    HapticFeedback.mediumImpact();
    _pulseController.repeat(reverse: true);
    setState(() => _showSpeedHud = true);
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    if (!_isLongPressing) return;
    _isLongPressing = false;
    widget.playbackService.player?.setRate(_normalSpeed);
    _pulseController.stop();
    _pulseController.reset();
    setState(() => _showSpeedHud = false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (d) => _onVerticalDragStart(d, constraints),
        onVerticalDragUpdate: (d) => _onVerticalDragUpdate(d, constraints),
        onVerticalDragEnd: _onVerticalDragEnd,
        onHorizontalDragStart: (d) => _onHorizontalDragStart(d, constraints),
        onHorizontalDragUpdate: (d) => _onHorizontalDragUpdate(d, constraints),
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onDoubleTap: () {
          if (!widget.enabled) return;
          final player = widget.playbackService.player;
          if (player == null) return;
          if (player.state.playing) {
            player.pause();
          } else {
            player.play();
          }
          HapticFeedback.lightImpact();
        },
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        child: Stack(
          children: [
            widget.child,

            // 拖动区域高亮
            if (_isDragging && _gestureType == _GestureType.brightness)
              Positioned(
                left: 0, top: 0, bottom: 0,
                width: constraints.maxWidth / 2,
                child: AnimatedOpacity(
                  opacity: _isDragging ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_isDragging && _gestureType == _GestureType.volume)
              Positioned(
                right: 0, top: 0, bottom: 0,
                width: constraints.maxWidth / 2,
                child: AnimatedOpacity(
                  opacity: _isDragging ? 1 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Colors.white.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 亮度 HUD
            if (_showBrightnessHud)
              Positioned(
                left: constraints.maxWidth * 0.12,
                top: 0, bottom: 0,
                child: Center(
                  child: _buildVerticalHud(
                    icon: _brightness < 0.05
                        ? Icons.brightness_low_rounded
                        : _brightness < 0.5
                            ? Icons.brightness_medium_rounded
                            : Icons.brightness_high_rounded,
                    value: _brightness,
                    color: const Color(0xFFFFD60A),
                  ),
                ),
              ),

            // 音量 HUD
            if (_showVolumeHud)
              Positioned(
                right: constraints.maxWidth * 0.12,
                top: 0, bottom: 0,
                child: Center(
                  child: _buildVerticalHud(
                    icon: _volume == 0
                        ? Icons.volume_off_rounded
                        : _volume < 0.4
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded,
                    value: _volume,
                    color: const Color(0xFF30D158),
                  ),
                ),
              ),

            // Seek HUD
            if (_showSeekHud)
              Positioned(
                top: 24, left: 0, right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _seekPosition >= _startPosition
                              ? Icons.fast_forward_rounded
                              : Icons.fast_rewind_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(_seekPosition),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_totalDuration > 0) ...[
                          Text(
                            ' / ${_formatDuration(_totalDuration)}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            // 加速 HUD
            Positioned(
              top: 24,
              left: 0, right: 0,
              child: AnimatedOpacity(
                opacity: _showSpeedHud ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Center(child: _buildSpeedHud()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalHud({
    required IconData icon,
    required double value,
    required Color color,
  }) {
    return AnimatedScale(
      scale: _isDragging ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Container(
        width: 40,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 10),
            // 竖向进度条
            SizedBox(
              height: 80,
              width: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    FractionallySizedBox(
                      heightFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(value * 100).round()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final s = seconds.round();
    final m = s ~/ 60;
    final h = m ~/ 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Widget _buildSpeedHud() {
    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fast_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              '2× 倍速',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
