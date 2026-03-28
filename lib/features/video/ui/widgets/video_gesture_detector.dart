import 'dart:async';
import 'package:flutter/material.dart';
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

class _VideoGestureDetectorState extends State<VideoGestureDetector> {
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

  Timer? _hudHideTimer;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  void _showHud(_GestureType type) {
    _hudHideTimer?.cancel();
    setState(() {
      _showBrightnessHud = type == _GestureType.brightness;
      _showVolumeHud = type == _GestureType.volume;
    });
    _hudHideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
        _showBrightnessHud = false;
        _showVolumeHud = false;
      });
      }
    });
  }

  bool _isLeftSide(Offset pos, BoxConstraints c) => pos.dx < c.maxWidth / 2;

  void _onVerticalDragStart(DragStartDetails d, BoxConstraints c) {
    if (!widget.enabled) return;
    _startDragY = d.localPosition.dy;
    final isLeft = _isLeftSide(d.localPosition, c);
    _gestureType = isLeft ? _GestureType.brightness : _GestureType.volume;
    if (isLeft) {
      ScreenBrightness().current.then((v) => _startValue = v);
    } else {
      VolumeController().getVolume().then((v) => _startValue = v);
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails d, BoxConstraints c) {
    if (!widget.enabled || _gestureType == _GestureType.none) return;
    final dy = _startDragY - d.localPosition.dy;
    final delta = dy / c.maxHeight;
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
  }

  void _onLongPressStart(LongPressStartDetails _) {
    if (!widget.enabled) return;
    _isLongPressing = true;
    final player = widget.playerController?.player;
    if (player != null) {
      _normalSpeed = player.state.rate;
      player.setRate(2.0);
    }
    setState(() => _showSpeedHud = true);
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    if (!_isLongPressing) return;
    _isLongPressing = false;
    widget.playerController?.player?.setRate(_normalSpeed);
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
            if (_showBrightnessHud)
              Positioned(
                left: 0, top: 0, bottom: 0,
                width: constraints.maxWidth / 2,
                child: _buildHud(
                  icon: Icons.wb_sunny_rounded,
                  value: _brightness,
                ),
              ),
            if (_showVolumeHud)
              Positioned(
                right: 0, top: 0, bottom: 0,
                width: constraints.maxWidth / 2,
                child: _buildHud(
                  icon: _volume == 0
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  value: _volume,
                ),
              ),
            if (_showSpeedHud)
              Positioned(
                top: 16,
                left: 0, right: 0,
                child: Center(child: _buildSpeedHud()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHud({required IconData icon, required double value}) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 8),
            SizedBox(
              width: 72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedHud() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fast_forward_rounded, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text('2× 加速中',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }
}
