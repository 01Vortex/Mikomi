import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/video_state.dart';

class VideoPageState {
  final String title;
  final String? animeTitle;
  final int? bangumiId;
  final VideoPlaybackService playbackService;
  final VideoPlayerState player;
  final VideoEpisodeState episode;
  final VideoDanmakuState danmaku;
  final VideoSourceState source;
  final Duration? initialProgress;

  const VideoPageState({
    required this.title,
    required this.animeTitle,
    required this.bangumiId,
    required this.playbackService,
    required this.player,
    required this.episode,
    required this.danmaku,
    required this.source,
    required this.initialProgress,
  });
}
