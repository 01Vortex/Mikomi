import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/config/themes/app_colors.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/ui/widgets/fullscreen_video.dart';
import 'package:mikomi/core/models/episode.dart';
import 'package:media_kit_video/media_kit_video.dart';

class FullscreenVideoPage extends StatefulWidget {
  final VideoPlaybackService playerController;
  final String title;
  final int currentEpisode;
  final String? episodeTitle;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final bool hasNextEpisode;
  final bool hasPreviousEpisode;
  final List<Episode> episodes;
  final Function(Episode)? onEpisodeSelected;
  final bool isLoadingEpisodes;
  final bool isDescending;
  final VoidCallback? onToggleSort;

  const FullscreenVideoPage({
    super.key,
    required this.playerController,
    required this.title,
    required this.currentEpisode,
    this.episodeTitle,
    this.onNextEpisode,
    this.onPreviousEpisode,
    this.hasNextEpisode = false,
    this.hasPreviousEpisode = false,
    this.episodes = const [],
    this.onEpisodeSelected,
    this.isLoadingEpisodes = false,
    this.isDescending = false,
    this.onToggleSort,
  });

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  @override
  void initState() {
    super.initState();
    _enterFullscreen();
  }

  void _enterFullscreen() {
    // 立即隐藏状态栏和导航栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 设置横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _exitFullscreen() {
    // 立即恢复状态栏 - 与视频页面保持一致
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: AppColors.surface,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    // 恢复竖屏
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _exitFullscreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.playerController.videoController;

    if (controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _exitFullscreen();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 视频播放器
            Positioned.fill(
              child: Video(
                controller: controller,
                controls: NoVideoControls,
                fit: BoxFit.cover,
              ),
            ),

            // 自定义控制器
            FullscreenVideoControls(
              playerController: widget.playerController,
              title: widget.title,
              currentEpisode: widget.currentEpisode,
              episodeTitle: widget.episodeTitle,
              onExitFullscreen: () => Navigator.of(context).pop(),
              onNextEpisode: widget.onNextEpisode,
              onPreviousEpisode: widget.onPreviousEpisode,
              hasNextEpisode: widget.hasNextEpisode,
              hasPreviousEpisode: widget.hasPreviousEpisode,
              episodes: widget.episodes,
              onEpisodeSelected: widget.onEpisodeSelected,
              isLoadingEpisodes: widget.isLoadingEpisodes,
              isDescending: widget.isDescending,
              onToggleSort: widget.onToggleSort,
            ),
          ],
        ),
      ),
    );
  }
}
