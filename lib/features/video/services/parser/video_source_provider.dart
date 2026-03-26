import 'dart:async';

import 'package:mikomi/features/video/services/webview_video_parser.dart';

enum VideoSourceType { online, cached }

class VideoSource {
  final String url;
  final int offset;
  final VideoSourceType type;

  const VideoSource({
    required this.url,
    required this.offset,
    required this.type,
  });
}

class VideoSourceNotFoundException implements Exception {
  final String message;
  const VideoSourceNotFoundException([this.message = 'Video source not found']);

  @override
  String toString() => 'VideoSourceNotFoundException: $message';
}

class VideoSourceTimeoutException implements Exception {
  final Duration timeout;
  const VideoSourceTimeoutException(this.timeout);

  @override
  String toString() =>
      'VideoSourceTimeoutException: Timed out after ${timeout.inSeconds}s';
}

class VideoSourceCancelledException implements Exception {
  const VideoSourceCancelledException();

  @override
  String toString() => 'VideoSourceCancelledException: Resolution was cancelled';
}

class CaptchaRequiredException implements Exception {
  final String pluginName;
  final String pageUrl;
  final int captchaType;
  final String captchaImageXpath;
  final String captchaInputXpath;
  final String captchaButtonXpath;

  CaptchaRequiredException({
    required this.pluginName,
    required this.pageUrl,
    required this.captchaType,
    required this.captchaImageXpath,
    required this.captchaInputXpath,
    required this.captchaButtonXpath,
  });

  @override
  String toString() {
    return 'CaptchaRequiredException(plugin=$pluginName, page=$pageUrl, type=$captchaType)';
  }
}

abstract class IVideoSourceProvider {
  Future<VideoSource> resolve(
    String episodeUrl, {
    required bool useLegacyParser,
    int offset = 0,
    Duration timeout = const Duration(seconds: 30),
  });

  void cancel();

  void dispose();
}

class WebViewVideoSourceProvider implements IVideoSourceProvider {
  final WebviewVideoParser _parser = WebviewVideoParser();
  int _resolveId = 0;

  @override
  Future<VideoSource> resolve(
    String episodeUrl, {
    required bool useLegacyParser,
    int offset = 0,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _resolveId++;
    final currentResolveId = _resolveId;

    try {
      final result = await _parser.parseVideoUrl(
        episodeUrl,
        useLegacyParser: useLegacyParser,
        timeout: timeout,
        maxDepth: 3,
      );

      if (currentResolveId != _resolveId) {
        throw const VideoSourceCancelledException();
      }

      if (result == null || result.isEmpty) {
        throw const VideoSourceNotFoundException();
      }

      return VideoSource(
        url: result,
        offset: offset,
        type: VideoSourceType.online,
      );
    } on TimeoutException {
      throw VideoSourceTimeoutException(timeout);
    }
  }

  @override
  void cancel() {
    _resolveId++;
  }

  @override
  void dispose() {
    cancel();
    unawaited(_parser.dispose());
  }
}
