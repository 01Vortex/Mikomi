import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

class VideoGestureDetector extends StatefulWidget {
  final Widget child;
  final VideoPlaybackService? playerController;
  final bool enabled;

  const VideoGestureDetector({
    super.key,
    required this.child,
    this.playerController,
    this.enabled = true,
  });

  @override
  State<VideoGestureDetector> createState() => _VideoGestureDetectorState();
}

enum _GestureType { none, brightness, volume }

class _VideoGestureDetectorState extends State<VideoGestureDetector>
    with TickerProviderStateMixin {
  _GestureType _gestureType = _GestureType.none;
  double _startDragY = 0;
  double _startValue = 0;

  bool _showBrightnessHud = false;
  bool _showVolumeHud = false;
  bool _showSpeedHud = false;
  double _brightness = 0.5;
  double _volume = 0.5;
  double _normalSpeed = 1.0;
  bool _isLongPressing = false;
  bool _isDragging = false;

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

    VolumeController().listener((v) {
      if (mounted) setState(() => _volume = v);
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
    VolumeController().removeListener();
    _hudHideTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _showHud(_GestureType type) {
    _hudHideTimer?.cancel();
    setState(() {
      _showBrightnessHud = type == _GestureType.brightness;
      _showVolumeHud = type == _GestureType.volume;
    });
    _hudHideTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showBrightnessHud = false;
          _showVolumeHud = false;
          _isDragging = false;
        });
      }
    });
  }

  bool _isLeftSide(Offset pos, BoxConstraints c) => pos.dx < c.maxWidth / 2;

  void _onVerticalDragStart(DragStartDetails d, BoxConstraints c) {
    if (!widget.enabled) return;
    _startDragY = d.localPosition.dy;
    _isDragging = true;
    final isLeft = _isLeftSide(d.localPosition, c);
    _gestureType = isLeft ? _GestureType.brightness : _GestureType.volume;
    HapticFeedback.selectionClick();
    if (isLeft) {
      ScreenBrightness().current.then((v) => _startValue = v);
    } else {
      VolumeController().getVolume().then((v) => _startValue = v);
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails d, BoxConstraints c) {
    if (!widget.enabled || _gestureType == _GestureType.none) return;
    final dy = _startDragY - d.localPosition.dy;
    final delta = dy / (c.maxHeight * 0.7);
    final newVal = (_startValue + delta).clamp(0.0, 1.0);
    if (_gestureType == _GestureType.brightness) {
      ScreenBrightness().setScreenBrightness(newVal);
      setState(() => _brightness = newVal);
      _showHud(_GestureType.brightness);
    } else {
      VolumeController().setVolume(newVal);
      setState(() => _volume = newVal);
      _showHud(_GestureType.volume);
    }
  }

  void _onVerticalDragEnd(DragEndDetails _) {
    _gestureType = _GestureType.none;
    _isDragging = false;
  }

  void _onLongPressStart(LongPressStartDetails _) {
    if (!widget.enabled) return;
    _isLongPressing = true;
    final player = widget.playerController?.player;
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
    widget.playerController?.player?.setRate(_normalSpeed);
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

            // 加速 HUD
            AnimatedOpacity(
              opacity: _showSpeedHud ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: _showSpeedHud
                  ? Positioned(
                      top: 20,
                      left: 0, right: 0,
                      child: Center(child: _buildSpeedHud()),
                    )
                  : const SizedBox.shrink(),
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

  Widget _buildSpeedHud() {
    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fast_forward_rounded,
              color: Colors.white,
              size: 15,
            ),
            const SizedBox(width: 5),
            Text(
              '2× 倍速',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
