import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/features/video/controllers/video_player_controller.dart';
import 'package:mikomi/features/video/ui/widgets/fullscreen_video_controls.dart';
import 'package:media_kit_video/media_kit_video.dart';

class FullscreenVideoPage extends StatefulWidget {
  final VideoPlayerController playerController;
  final String title;
  final int currentEpisode;
  final String? episodeTitle;
  final VoidCallback? onNextEpisode;
  final VoidCallback? onPreviousEpisode;
  final bool hasNextEpisode;
  final bool hasPreviousEpisode;

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
    // 设置横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 隐藏状态栏和导航栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullscreen() {
    // 恢复竖屏
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // 恢复状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
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
            ),
          ],
        ),
      ),
    );
  }
}
