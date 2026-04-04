import 'package:mikomi/features/my/models/history_model.dart';
import 'package:mikomi/features/my/service/watch_history_service.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';

class VideoHistoryService {
  final HistoryModelService _historyService = HistoryModelService();

  void saveHistoryModel({
    required int? bangumiId,
    required String title,
    required String? animeTitle,
    required int currentEpisode,
    required String? currentSmallTitle,
    required String? currentSourceName,
    required String lastResolvedVideoUrl,
    required VideoPlaybackService playbackService,
  }) {
    if (bangumiId == null || title.isEmpty) return;
    if (playbackService.player == null || !playbackService.isInitialized) {
      return;
    }

    try {
      final progress = playbackService.player!.state.position;
      final duration = playbackService.player!.state.duration;
      if (progress.inSeconds == 0 || duration.inSeconds == 0) return;

      _historyService.addHistory(
        HistoryModel(
          bangumiId: bangumiId,
          bangumiName: title,
          bangumiNameCn: animeTitle ?? title,
          lastWatchEpisode: currentEpisode,
          lastWatchEpisodeName: currentSmallTitle ?? '',
          lastWatchTime: DateTime.now(),
          pluginName: currentSourceName ?? '',
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
