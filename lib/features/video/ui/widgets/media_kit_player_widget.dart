import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:mikomi/features/video/controllers/video_player_controller.dart';

class MediaKitPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String title;
  final int currentEpisode;
  final int totalEpisodes;
  final VideoPlayerController playerController;

  const MediaKitPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.currentEpisode,
    required this.totalEpisodes,
    required this.playerController,
  });

  @override
  State<MediaKitPlayerWidget> createState() => _MediaKitPlayerWidgetState();
}

class _MediaKitPlayerWidgetState extends State<MediaKitPlayerWidget> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.playerController.initialize();

      if (mounted && widget.videoUrl.isNotEmpty) {
        await widget.playerController.play(widget.videoUrl);
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('播放器初始化失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '视频加载失败: $e';
        });
      }
    }
  }

  @override
  void didUpdateWidget(MediaKitPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoUrl != widget.videoUrl && widget.videoUrl.isNotEmpty) {
      _initPlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _initPlayer, child: const Text('重试')),
            ],
          ),
        ),
      );
    }

    final controller = widget.playerController.videoController;

    if (_isLoading ||
        !widget.playerController.isInitialized ||
        controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Video(controller: controller, controls: MaterialVideoControls);
  }
}
