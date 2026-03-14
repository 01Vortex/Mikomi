import 'package:flutter/material.dart';
import 'package:mikomi/features/anime/ui/widgets/video_source_selector.dart';

class PlayButton extends StatelessWidget {
  final VoidCallback? onPlay;
  final List<VideoSource>? videoSources;

  const PlayButton({super.key, this.onPlay, this.videoSources});

  void _showVideoSourceSelector(BuildContext context) {
    if (videoSources == null || videoSources!.isEmpty) {
      // 如果没有视频源,直接调用onPlay
      onPlay?.call();
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VideoSourceSelector(
        sources: videoSources!,
        onSourceSelected: (source) {
          // 处理视频源选择
          print('选择了视频源: ${source.name}');
          onPlay?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      icon: const Icon(Icons.play_arrow_rounded),
      label: const Text('开始观看'),
      onPressed: () => _showVideoSourceSelector(context),
    );
  }
}
