import 'package:flutter/material.dart';
import 'package:mikomi/features/video/ui/widgets/smallscreen_video.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/core/models/episode.dart';

class VideoPlayerArea extends StatelessWidget {
  final String videoUrl;
  final String title;
  final int currentEpisode;
  final int totalEpisodes;
  final VideoPlaybackService playerController;
  final String? episodeTitle;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final bool hasNextEpisode;
  final bool hasPreviousEpisode;
  final Duration? initialProgress;
  final List<Episode> episodes;
  final Function(Episode) onEpisodeSelected;
  final bool isLoadingEpisodes;
  final bool isDescending;
  final VoidCallback onToggleSort;
  final bool isDanmakuEnabled;
  final String? animeTitle;
  final int? bangumiId;
  final Function(bool) onDanmakuToggle;
  final bool isLoading;
  final bool hasError;
  final bool showTimeoutHint;
  final VoidCallback onRetry;

  const VideoPlayerArea({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.currentEpisode,
    required this.totalEpisodes,
    required this.playerController,
    this.episodeTitle,
    this.onNextEpisode,
    this.onPreviousEpisode,
    required this.hasNextEpisode,
    required this.hasPreviousEpisode,
    this.initialProgress,
    required this.episodes,
    required this.onEpisodeSelected,
    required this.isLoadingEpisodes,
    required this.isDescending,
    required this.onToggleSort,
    required this.isDanmakuEnabled,
    this.animeTitle,
    this.bangumiId,
    required this.onDanmakuToggle,
    required this.isLoading,
    required this.hasError,
    required this.showTimeoutHint,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Colors.black,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            if (videoUrl.isNotEmpty)
              SmallscreenVideo(
                videoUrl: videoUrl,
                title: title,
                currentEpisode: currentEpisode,
                totalEpisodes: totalEpisodes,
                playerController: playerController,
                episodeTitle: episodeTitle,
                onNextEpisode: onNextEpisode,
                onPreviousEpisode: onPreviousEpisode,
                hasNextEpisode: hasNextEpisode,
                hasPreviousEpisode: hasPreviousEpisode,
                initialProgress: initialProgress,
                episodes: episodes,
                onEpisodeSelected: onEpisodeSelected,
                isLoadingEpisodes: isLoadingEpisodes,
                isDescending: isDescending,
                onToggleSort: onToggleSort,
                isDanmakuEnabled: isDanmakuEnabled,
                animeTitle: animeTitle,
                bangumiId: bangumiId,
                onDanmakuToggle: onDanmakuToggle,
              ),
            if (hasError && !isLoading)
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white70, size: 40),
                      const SizedBox(height: 12),
                      const Text('视频解析失败，请切换视频源重试',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
              ),
            if (isLoading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3),
                    const SizedBox(height: 16),
                    Text('解析中',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14)),
                    if (showTimeoutHint) ...[
                      const SizedBox(height: 12),
                      Text('加载时间较长，点击右下角切换视频源',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13)),
                    ],
                  ],
                ),
              ),
            if ((isLoading || hasError) && videoUrl.isEmpty)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, top: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
