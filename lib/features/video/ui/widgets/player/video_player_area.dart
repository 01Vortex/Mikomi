import 'package:flutter/material.dart';
import 'package:mikomi/features/video/controller/video_page_controller.dart';
import 'package:mikomi/features/video/state/video_page_state.dart';
import 'package:mikomi/features/video/ui/widgets/player/smallscreen_controls.dart';

/// 视频播放区域（小屏），包装 [SmallscreenVideo] 并处理加载/错误/超时状态。
///
/// 重构后：接受 [VideoPageController] + [VideoPageState] 替代原本的 29 个独立参数。
class VideoPlayerArea extends StatelessWidget {
  final double? videoHeight;
  final VideoPageState pageState;
  final VideoPageController controller;
  final void Function(bool enabled)? onDanmakuToggle;

  const VideoPlayerArea({
    super.key,
    this.videoHeight,
    required this.pageState,
    required this.controller,
    this.onDanmakuToggle,
  });

  @override
  Widget build(BuildContext context) {
    final player = pageState.player;
    final width = MediaQuery.of(context).size.width;
    final height = videoHeight ?? (width / (16 / 9));

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            if (player.resolvedVideoUrl.isNotEmpty)
              Positioned.fill(
                child: SmallscreenVideo(
                  pageState: pageState,
                  controller: controller,
                  onDanmakuToggle: onDanmakuToggle,
                ),
              ),
            if (player.hasPlaybackError && !player.isResolvingVideo)
              const Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.white70, size: 40),
                      SizedBox(height: 12),
                      Text(
                        '视频解析失败，请切换视频源',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            if (player.isResolvingVideo)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    if (player.showTimeoutNotice) ...[
                      const SizedBox(height: 12),
                      Text(
                        '视频加载慢，可点右下角换源',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            if ((player.isResolvingVideo || player.hasPlaybackError) &&
                player.resolvedVideoUrl.isEmpty)
              _topFallback(context),
          ],
        ),
      ),
    );
  }

  Widget _topFallback(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 10, right: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  pageState.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
