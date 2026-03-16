import 'package:flutter/material.dart';
import 'package:mikomi/features/video/ui/widgets/media_kit_player_widget.dart';
import 'package:mikomi/features/video/controllers/video_player_controller.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String title;
  final int currentEpisode;
  final int totalEpisodes;
  final String? episodeTitle;
  final VideoPlayerController playerController;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.currentEpisode,
    required this.totalEpisodes,
    required this.playerController,
    this.episodeTitle,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 播放器高度 = 16:9比例
    final playerHeight = screenWidth * 9 / 16;

    return Container(
      width: screenWidth,
      height: playerHeight,
      color: Colors.black,
      child: widget.videoUrl.isNotEmpty
          ? MediaKitPlayerWidget(
              videoUrl: widget.videoUrl,
              title: widget.title,
              currentEpisode: widget.currentEpisode,
              totalEpisodes: widget.totalEpisodes,
              playerController: widget.playerController,
              episodeTitle: widget.episodeTitle,
            )
          : Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 80,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
    );
  }
}
