import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mikomi/features/video/controllers/video_player_controller.dart';
import 'package:mikomi/features/video/ui/widgets/media_kit_player_widget.dart';

class VideoPlayPage extends StatefulWidget {
  final String videoUrl;
  final String title;
  final int currentEpisode;
  final int totalEpisodes;

  const VideoPlayPage({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.currentEpisode,
    required this.totalEpisodes,
  });

  @override
  State<VideoPlayPage> createState() => _VideoPlayPageState();
}

class _VideoPlayPageState extends State<VideoPlayPage> {
  late final VideoPlayerController _playerController;

  @override
  void initState() {
    super.initState();
    _playerController = VideoPlayerController();

    // 设置横屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // 隐藏状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _playerController.dispose();

    // 恢复竖屏
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // 恢复状态栏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 视频播放器
          Center(
            child: MediaKitPlayerWidget(
              videoUrl: widget.videoUrl,
              title: widget.title,
              currentEpisode: widget.currentEpisode,
              totalEpisodes: widget.totalEpisodes,
              playerController: _playerController,
            ),
          ),

          // 返回按钮
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
