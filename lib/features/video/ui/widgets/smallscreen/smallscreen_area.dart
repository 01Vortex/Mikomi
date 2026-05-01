import 'package:flutter/material.dart';
import 'package:mikomi/features/settings/danmaku/danmaku_setting_service.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/ui/widgets/smallscreen/smallscreen_video.dart';

class VideoPlayerArea extends StatefulWidget {
  final double? videoHeight;
  final String videoUrl;
  final String title;
  final int currentEpisode;
  final int totalEpisodes;
  final VideoPlaybackService playbackService;
  final String? currentSmallTitle;
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
    this.videoHeight,
    required this.videoUrl,
    required this.title,
    required this.currentEpisode,
    required this.totalEpisodes,
    required this.playbackService,
    this.currentSmallTitle,
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
  State<VideoPlayerArea> createState() => _VideoPlayerAreaState();
}

class _VideoPlayerAreaState extends State<VideoPlayerArea> {
  DanmakuConfig _danmakuConfig = const DanmakuConfig();

  @override
  void initState() {
    super.initState();
    _loadDanmakuConfig();
  }

  @override
  void didUpdateWidget(covariant VideoPlayerArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDanmakuEnabled != widget.isDanmakuEnabled) {
      _loadDanmakuConfig();
    }
  }

  Future<void> _loadDanmakuConfig() async {
    final config = await DanmakuSettingService.loadAll();
    if (!mounted) return;
    setState(() => _danmakuConfig = config);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = widget.videoHeight ?? (width / (16 / 9));

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            if (widget.videoUrl.isNotEmpty)
              Positioned.fill(
                child: SmallscreenVideo(
                  key: ValueKey(
                    '${_danmakuConfig.fontSize}-'
                    '${_danmakuConfig.opacity}-'
                    '${_danmakuConfig.area}-'
                    '${_danmakuConfig.duration}-'
                    '${_danmakuConfig.strokeWidth}-'
                    '${_danmakuConfig.showTop}-'
                    '${_danmakuConfig.showBottom}-'
                    '${_danmakuConfig.showScroll}-'
                    '${widget.currentEpisode}-'
                    '${widget.isDanmakuEnabled}',
                  ),
                  danmakuConfigOverride: _danmakuConfig,
                  videoUrl: widget.videoUrl,
                  title: widget.title,
                  currentEpisode: widget.currentEpisode,
                  totalEpisodes: widget.totalEpisodes,
                  playbackService: widget.playbackService,
                  currentSmallTitle: widget.currentSmallTitle,
                  onNextEpisode: widget.onNextEpisode,
                  onPreviousEpisode: widget.onPreviousEpisode,
                  hasNextEpisode: widget.hasNextEpisode,
                  hasPreviousEpisode: widget.hasPreviousEpisode,
                  initialProgress: widget.initialProgress,
                  episodes: widget.episodes,
                  onEpisodeSelected: widget.onEpisodeSelected,
                  isLoadingEpisodes: widget.isLoadingEpisodes,
                  isDescending: widget.isDescending,
                  onToggleSort: widget.onToggleSort,
                  isDanmakuEnabled: widget.isDanmakuEnabled,
                  animeTitle: widget.animeTitle,
                  bangumiId: widget.bangumiId,
                  onDanmakuToggle: widget.onDanmakuToggle,
                ),
              ),
            if (widget.hasError && !widget.isLoading)
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white70, size: 40),
                      const SizedBox(height: 12),
                      const Text('视频解析失败，请切换视频源',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            if (widget.isLoading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 3),
                    if (widget.showTimeoutHint) ...[
                      const SizedBox(height: 12),
                      Text('视频加载慢，可点右下角换源',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13)),
                    ],
                  ],
                ),
              ),
            if ((widget.isLoading || widget.hasError) && widget.videoUrl.isEmpty)
              Positioned(
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            widget.title,
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
              ),
          ],
        ),
      ),
    );
  }
}
