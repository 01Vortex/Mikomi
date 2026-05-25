import 'package:flutter/material.dart';
import 'package:mikomi/features/video/controller/video_page_controller.dart';
import 'package:mikomi/features/video/state/video_page_state.dart';
import 'package:mikomi/features/video/ui/widgets/player/video_player_area.dart';

/// 视频页面顶部：播放器区域组装
class VideoPlayerSection extends StatelessWidget {
  final VideoPageState pageState;
  final double videoHeight;
  final Future<void> Function(bool enabled) onDanmakuToggle;
  final VideoPageController controller;

  const VideoPlayerSection({
    super.key,
    required this.pageState,
    required this.videoHeight,
    required this.onDanmakuToggle,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return VideoPlayerArea(
      videoHeight: videoHeight,
      pageState: pageState,
      controller: controller,
      onDanmakuToggle: onDanmakuToggle,
    );
  }
}
