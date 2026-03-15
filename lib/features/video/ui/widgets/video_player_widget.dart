import 'package:flutter/material.dart';
import 'package:mikomi/features/video/ui/widgets/media_kit_player_widget.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String title;
  final int currentEpisode;
  final int totalEpisodes;
  final String? episodeTitle;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.currentEpisode,
    required this.totalEpisodes,
    this.episodeTitle,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final playerHeight = screenWidth * 9 / 16;

    return Container(
      width: screenWidth,
      height: playerHeight,
      color: Colors.black,
      child: Stack(
        children: [
          if (widget.videoUrl.isNotEmpty)
            MediaKitPlayerWidget(
              videoUrl: widget.videoUrl,
              title: widget.title,
              currentEpisode: widget.currentEpisode,
              totalEpisodes: widget.totalEpisodes,
            )
          else
            Center(
              child: Icon(
                Icons.play_circle_outline,
                size: 80,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16,
                12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.episodeTitle != null &&
                            widget.episodeTitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '第${widget.currentEpisode}集 ${widget.episodeTitle}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else
                          Text(
                            '第${widget.currentEpisode}集',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
