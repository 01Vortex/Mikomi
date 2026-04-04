import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/models/video_plugin.dart';
import 'package:mikomi/features/video/parse/parsing.dart';
import 'package:mikomi/features/video/repository/video_source_repository.dart';
import 'package:mikomi/features/video/repository/video_stream_repository.dart';
import 'package:mikomi/features/video/exception/video_exception.dart';

class VideoParsingService {
  final VideoSourceRepository _sourceRepository;
  final VideoStreamRepository _streamRepository;
  final Parsing _parsing;
  StreamSubscription<(String, int)>? _parserSubscription;
  Completer<String>? _resolveCompleter;
  bool _disposed = false;

  VideoParsingService({
    VideoSourceRepository? sourceRepository,
    VideoStreamRepository? streamRepository,
    Parsing? parsing,
  }) : _sourceRepository = sourceRepository ?? VideoSourceRepository(),
       _streamRepository = streamRepository ?? VideoStreamRepository(),
       _parsing = parsing ?? ParsingFactory.getController();

  bool isDirectStreamUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') || lower.contains('.mp4');
  }

  Future<String> resolveVideoUrl(
    String url,
    String? pluginName,
    List<Episode> episodes,
    int currentEpisode,
  ) async {
    try {
      if (episodes.isEmpty) {
        if (isDirectStreamUrl(url)) return url;
        if (pluginName != null && url.isNotEmpty) {
          return await _resolveAndCache(pluginName: pluginName, pageUrl: url);
        }
        return url;
      }

      final episodeUrl = episodes
              .firstWhere((ep) => ep.number == currentEpisode)
              .url ??
          url;

      if (pluginName != null) {
        return await _resolveAndCache(pluginName: pluginName, pageUrl: episodeUrl);
      }
      return episodeUrl;
    } on VideoStreamCancelledException {
      return '';
    } catch (e) {
      debugPrint('获取视频URL失败: $e');
      rethrow;
    }
  }

  Future<String> refreshParsedUrl(
    String pageUrl,
    String pluginName,
    String lastResolvedUrl,
  ) async {
    try {
      final parsedUrl = await _resolveFromPage(pageUrl, pluginName);
      if (parsedUrl.isEmpty || parsedUrl == lastResolvedUrl) {
        return lastResolvedUrl;
      }
      _streamRepository.saveCachedStreamUrl(_cacheKey(pluginName, pageUrl), parsedUrl);
      return parsedUrl;
    } catch (e) {
      debugPrint('静默刷新失败: $e');
      return lastResolvedUrl;
    }
  }

  Future<String> _resolveAndCache({
    required String pluginName,
    required String pageUrl,
  }) async {
    final key = _cacheKey(pluginName, pageUrl);
    final cached = _streamRepository.getCachedStreamUrl(key);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final parsedUrl = await _resolveFromPage(pageUrl, pluginName);
    if (parsedUrl.isNotEmpty) {
      _streamRepository.saveCachedStreamUrl(key, parsedUrl);
    }
    return parsedUrl;
  }

  Future<String> _resolveFromPage(String pageUrl, String pluginName) async {
    _ensureActive();
    cancelParsing();

    final plugin = _sourceRepository.getPluginByName(pluginName);
    if (plugin == null) {
      throw const VideoException(VideoExceptionCode.pluginNotFound);
    }

    if (!plugin.useWebview) return pageUrl;

    _resolveCompleter = Completer<String>();
    await _parsing.init();

    _parserSubscription = _parsing.onVideoURLParser.listen((event) {
      if (_resolveCompleter?.isCompleted ?? true) return;
      final (url, _) = event;
      if (url.trim().isEmpty) return;
      _resolveCompleter?.complete(url);
    });

    await _parsing.loadUrl(
      pageUrl,
      plugin.useLegacyParser,
      options: _buildOptions(plugin),
    );

    try {
      return await _resolveCompleter!.future.timeout(const Duration(seconds: 45));
    } on TimeoutException {
      cancelParsing();
      throw VideoStreamTimeoutException(const Duration(seconds: 45));
    }
  }

  VideoStreamResolveOptions _buildOptions(VideoPlugin plugin) {
    return VideoStreamResolveOptions(
      captchaType: plugin.antiCrawlerConfig.captchaType,
      captchaImageXpath: plugin.antiCrawlerConfig.captchaImage,
      captchaInputXpath: plugin.antiCrawlerConfig.captchaInput,
      captchaButtonXpath: plugin.antiCrawlerConfig.captchaButton,
    );
  }

  String _cacheKey(String pluginName, String pageUrl) => '$pluginName::$pageUrl';

  void cancelParsing() {
    _parserSubscription?.cancel();
    _parserSubscription = null;
    if (_resolveCompleter != null && !(_resolveCompleter!.isCompleted)) {
      _resolveCompleter!.completeError(const VideoStreamCancelledException());
    }
    _resolveCompleter = null;
    unawaited(_parsing.unloadPage());
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    cancelParsing();
    _parsing.dispose();
  }

  void _ensureActive() {
    if (_disposed) {
      throw const VideoException(
        VideoExceptionCode.parseFailed,
        detail: '解析器已释放',
      );
    }
  }
}

class VideoStreamResolveOptions {
  final int captchaType;
  final String captchaImageXpath;
  final String captchaInputXpath;
  final String captchaButtonXpath;

  const VideoStreamResolveOptions({
    this.captchaType = 0,
    this.captchaImageXpath = '',
    this.captchaInputXpath = '',
    this.captchaButtonXpath = '',
  });
}
