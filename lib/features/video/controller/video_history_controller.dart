import 'dart:async';

import 'package:mikomi/features/video/services/video_history_service.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/video_state.dart';

class VideoHistoryController {
  final VideoHistoryService _historyService;
  final VideoPlaybackService _playbackService;
  final String title;
  final String? animeTitle;
  final int? bangumiId;
  final Duration interval;

  Timer? _timer;

  VideoHistoryController({
    required VideoHistoryService historyService,
    required VideoPlaybackService playbackService,
    required this.title,
    required this.animeTitle,
    required this.bangumiId,
    this.interval = const Duration(seconds: 10),
  }) : _historyService = historyService,
       _playbackService = playbackService;

  void start({required VideoState Function() getState}) {
    stop();
    _timer = Timer.periodic(interval, (_) {
      save(getState());
    });
  }

  void save(VideoState state) {
    _historyService.saveHistory(
      bangumiId: bangumiId,
      title: title,
      animeTitle: animeTitle,
      currentEpisode: state.currentEpisodeNumber,
      currentSmallTitle: state.currentSmallTitle,
      currentSourceName: state.currentSourceName,
      lastResolvedVideoUrl: state.lastResolvedVideoUrl,
      playbackService: _playbackService,
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
  }
}
