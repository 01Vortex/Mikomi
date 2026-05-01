import 'package:mikomi/features/video/services/video_parsing_service.dart';
import 'package:mikomi/features/video/state/video_state.dart';

class VideoResolveController {
  final VideoParsingService _parsingService;

  int _silentRefreshToken = 0;
  int _resolveRequestToken = 0;

  VideoResolveController({required VideoParsingService parsingService})
    : _parsingService = parsingService;

  bool isDirectStreamUrl(String url) {
    return _parsingService.isDirectStreamUrl(url);
  }

  Future<VideoState?> refreshSilently({
    required VideoState state,
    required bool Function() isDisposed,
  }) async {
    if (state.currentSourceName == null || state.currentEpisode == null) {
      return null;
    }

    final token = ++_silentRefreshToken;
    try {
      final pageUrl = state.currentEpisode!.url ?? state.currentVideoPageUrl;
      final resolvedUrl = await _parsingService.refreshParsedUrl(
        pageUrl,
        state.currentSourceName!,
        state.lastResolvedVideoUrl,
      );

      if (!_canApplySilentRefreshResult(token, isDisposed) ||
          resolvedUrl.isEmpty ||
          resolvedUrl == state.lastResolvedVideoUrl) {
        return null;
      }

      return state.applyResolvedVideoUrl(resolvedUrl);
    } catch (_) {
      return null;
    }
  }

  Future<VideoState> resolve({
    required VideoState state,
    required bool Function() isDisposed,
  }) async {
    final token = ++_resolveRequestToken;
    try {
      final resolvedUrl = await _parsingService.resolveVideoUrl(
        state.currentVideoPageUrl,
        state.currentSourceName,
        state.episodes,
        state.currentEpisodeNumber,
      );

      if (!_canApplyResolveResult(token, isDisposed)) {
        return state;
      }

      return state.applyResolvedVideoUrl(resolvedUrl);
    } catch (error) {
      if (!_canApplyResolveResult(token, isDisposed)) {
        return state;
      }
      return state.applyResolveError(error);
    }
  }

  void cancelParsing() {
    _parsingService.cancelParsing();
  }

  void cancelPendingRequests() {
    _silentRefreshToken++;
    _resolveRequestToken++;
  }

  bool _canApplySilentRefreshResult(int token, bool Function() isDisposed) {
    return !isDisposed() && token == _silentRefreshToken;
  }

  bool _canApplyResolveResult(int token, bool Function() isDisposed) {
    return !isDisposed() && token == _resolveRequestToken;
  }
}
