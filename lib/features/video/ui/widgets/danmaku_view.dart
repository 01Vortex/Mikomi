import 'package:flutter/material.dart';
import 'package:canvas_danmaku/canvas_danmaku.dart';

class DanmakuView extends StatefulWidget {
  final Function(DanmakuController) onControllerCreated;
  final bool isPlaying;
  final Duration currentPosition;
  final double opacity;
  final double fontSize;
  final double speed;
  final double area;
  final double strokeWidth;

  const DanmakuView({
    super.key,
    required this.onControllerCreated,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.opacity = 1.0,
    this.fontSize = 16.0,
    this.speed = 8.0,
    this.area = 0.5,
    this.strokeWidth = 1.0,
  });

  @override
  State<DanmakuView> createState() => _DanmakuViewState();
}

class _DanmakuViewState extends State<DanmakuView> {
  @override
  Widget build(BuildContext context) {
    return DanmakuScreen(
      createdController: widget.onControllerCreated,
      option: DanmakuOption(
        fontSize: widget.fontSize,
        opacity: widget.opacity,
        duration: widget.speed,
        strokeWidth: widget.strokeWidth,
        area: widget.area,
      ),
    );
  }
}
