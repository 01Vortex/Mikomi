import 'package:mikomi/features/my/models/watch_history.dart';
import 'package:mikomi/core/services/watch_history_service.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';

class VideoHistoryService {
  final WatchHistoryService _historyService = WatchHistoryService();

  void saveWatchHistory({
    required int? bangumiId,
    required String title,
    required String? animeTitle,
    required int currentEpisode,
    required String? currentEpisodeTitle,
    required String? currentPluginName,
    required String lastResolvedVideoUrl,
    required VideoPlaybackService playerController,
  }) {
    if (bangumiId == null || title.isEmpty) return;
    if (playerController.player == null || !playerController.isInitialized) {
      return;
    }

    try {
      final progress = playerController.player!.state.position;
      final duration = playerController.player!.state.duration;
      if (progress.inSeconds == 0 || duration.inSeconds == 0) return;

      _historyService.addHistory(
        WatchHistory(
          bangumiId: bangumiId,
          bangumiName: title,
          bangumiNameCn: animeTitle ?? title,
          lastWatchEpisode: currentEpisode,
          lastWatchEpisodeName: currentEpisodeTitle ?? '',
          lastWatchTime: DateTime.now(),
          pluginName: currentPluginName ?? '',
          progress: progress,
          duration: duration,
          cachedPlayUrl: lastResolvedVideoUrl,
          cachedPlayUrlTime:
              lastResolvedVideoUrl.isNotEmpty ? DateTime.now() : null,
        ),
      );
    } catch (_) {}
  }
}
