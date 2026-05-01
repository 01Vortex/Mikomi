import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/controller/video_episode_controller.dart';
import 'package:mikomi/features/video/controller/video_resolve_controller.dart';
import 'package:mikomi/features/video/services/video_playback_service.dart';
import 'package:mikomi/features/video/state/video_state.dart';

class VideoSourceController {
  final VideoEpisodeController _episodeController;
  final VideoResolveController _resolveController;
  final VideoPlaybackService _playbackService;

  VideoSourceController({
    required VideoEpisodeController episodeController,
    required VideoResolveController resolveController,
    required VideoPlaybackService playbackService,
  }) : _episodeController = episodeController,
       _resolveController = resolveController,
       _playbackService = playbackService;

  Future<VideoState?> switchSource({
    required VideoState state,
    required VideoSource source,
    required bool Function() isDisposed,
  }) async {
    _resolveController.cancelParsing();
    await _playbackService.stop();

    final episodes = await _episodeController.loadEpisodes(source.name);
    if (isDisposed()) {
      return null;
    }

    return state.switchSource(sourceName: source.name, nextEpisodes: episodes);
  }
}
