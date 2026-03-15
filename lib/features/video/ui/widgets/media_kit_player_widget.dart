import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MediaKitPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String title;
  final int currentEpisode;
  final int totalEpisodes;

  const MediaKitPlayerWidget({
    super.key,
    required this.videoUrl,
    required this.title,
    required this.currentEpisode,
    required this.totalEpisodes,
  });

  @override
  State<MediaKitPlayerWidget> createState() => _MediaKitPlayerWidgetState();
}

class _MediaKitPlayerWidgetState extends State<MediaKitPlayerWidget> {
  Player? _player;
  VideoController? _controller;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (_isDisposed) return;

    try {
      debugPrint('创建播放器实例');
      _player = Player(
        configuration: const PlayerConfiguration(
          bufferSize: 50 * 1024 * 1024,
          logLevel: MPVLogLevel.error,
        ),
      );

      _controller = VideoController(_player!);

      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
        });
      }

      if (widget.videoUrl.isNotEmpty && mounted && !_isDisposed) {
        debugPrint('开始播放: ${widget.videoUrl}');
        await _player!.open(Media(widget.videoUrl));
      }
    } catch (e) {
      debugPrint('初始化播放器失败: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('开始释放播放器');
    _isDisposed = true;
    _disposePlayer();
    super.dispose();
  }

  void _disposePlayer() {
    final player = _player;
    final controller = _controller;

    _player = null;
    _controller = null;
    _isInitialized = false;

    if (player != null) {
      // 同步停止
      try {
        player.stop();
        debugPrint('播放器已停止');
      } catch (e) {
        debugPrint('停止播放失败: $e');
      }

      // 异步释放，延迟200ms确保停止完成
      Future.delayed(const Duration(milliseconds: 200), () async {
        try {
          await player.dispose();
          debugPrint('播放器已释放');
        } catch (e) {
          debugPrint('释放播放器失败: $e');
        }
      });
    }
  }

  @override
  void didUpdateWidget(MediaKitPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl &&
        widget.videoUrl.isNotEmpty &&
        !_isDisposed &&
        _player != null) {
      debugPrint('切换视频: ${widget.videoUrl}');
      _player!.open(Media(widget.videoUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized ||
        _player == null ||
        _controller == null ||
        _isDisposed) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Video(controller: _controller!, controls: MaterialVideoControls);
  }
}
