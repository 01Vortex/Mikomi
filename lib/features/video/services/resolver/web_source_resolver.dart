import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mikomi/features/anime/selector/video_source_selector.dart';
import 'package:mikomi/features/video/exception/video_exception.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/models/video_plugin.dart';
import 'package:mikomi/features/video/origin/web/parsing_engine.dart';
import 'package:mikomi/features/video/repository/video_source_repository.dart';
import 'package:mikomi/features/video/repository/video_stream_repository.dart';
import 'package:mikomi/features/video/models/stream_resolve_options.dart';
import 'package:mikomi/features/video/services/resolver/video_source_resolver.dart';

/// Web 爬虫解析器——通过 WebView 加载播放页面，注入 JS 提取视频流 URL。
class WebSourceResolver implements VideoSourceResolver {
  final VideoSourceRepository _sourceRepo;
  final VideoStreamRepository _streamRepo;
  final Parsing _parsing;

  StreamSubscription<(String, int)>? _parserSub;
  Completer<String>? _resolveCompleter;
  bool _disposed = false;

  WebSourceResolver({
    VideoSourceRepository? sourceRepo,
    VideoStreamRepository? streamRepo,
    Parsing? parsing,
  }) : _sourceRepo = sourceRepo ?? VideoSourceRepository(),
       _streamRepo = streamRepo ?? VideoStreamRepository(),
       _parsing = parsing ?? ParsingFactory.getController();

  // ── VideoSourceResolver 接口 ──

  @override
  bool isDirectStreamUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') || lower.contains('.mp4');
  }

  @override
  Future<String> resolveStreamUrl({
    required VideoSource source,
    required Episode episode,
  }) async {
    final pageUrl = episode.url ?? '';
    return _resolveWithCache(pluginName: source.name, pageUrl: pageUrl);
  }

  @override
  Future<String?> refreshStreamUrl({
    required VideoSource source,
    required Episode episode,
    required String lastResolvedUrl,
  }) async {
    final pageUrl = episode.url ?? '';
    try {
      final parsedUrl = await _resolveFromPage(pageUrl, source.name);
      if (parsedUrl.isEmpty || parsedUrl == lastResolvedUrl) {
        return null;
      }
      _streamRepo.saveCachedStreamUrl(
        _cacheKey(source.name, pageUrl),
        parsedUrl,
      );
      return parsedUrl;
    } catch (e) {
      debugPrint('WebSourceResolver: 静默刷新失败 - $e');
      return null;
    }
  }

  @override
  void cancel() {
    _parserSub?.cancel();
    _parserSub = null;
    if (_resolveCompleter != null && !_resolveCompleter!.isCompleted) {
      _resolveCompleter!.completeError(const VideoStreamCancelledException());
    }
    _resolveCompleter = null;
    unawaited(_parsing.unloadPage());
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    cancel();
    _parsing.dispose();
  }

  // ── Web 特有：兼容旧版调用（接受 pluginName + pageUrl） ──

  /// 解析视频 URL（旧兼容：直接传 pluginName + pageUrl）
  Future<String> resolveFromPage(String pluginName, String pageUrl) async {
    final cachedUrl = _streamRepo.getCachedStreamUrl(
      _cacheKey(pluginName, pageUrl),
    );
    if (cachedUrl != null && cachedUrl.isNotEmpty) return cachedUrl;
    return _resolveWithCache(pluginName: pluginName, pageUrl: pageUrl);
  }

  /// 强制重新解析（跳过缓存）
  Future<String> resolveFresh(String pluginName, String pageUrl) async {
    final parsedUrl = await _resolveFromPage(pageUrl, pluginName);
    if (parsedUrl.isNotEmpty) {
      _streamRepo.saveCachedStreamUrl(
        _cacheKey(pluginName, pageUrl),
        parsedUrl,
      );
    }
    return parsedUrl;
  }

  // ── 内部方法 ──

  Future<String> _resolveWithCache({
    required String pluginName,
    required String pageUrl,
  }) async {
    final key = _cacheKey(pluginName, pageUrl);
    final cached = _streamRepo.getCachedStreamUrl(key);
    if (cached != null && cached.isNotEmpty) return cached;

    final parsedUrl = await _resolveFromPage(pageUrl, pluginName);
    if (parsedUrl.isNotEmpty) {
      _streamRepo.saveCachedStreamUrl(key, parsedUrl);
    }
    return parsedUrl;
  }

  Future<String> _resolveFromPage(String pageUrl, String pluginName) async {
    _ensureActive();
    cancel(); // 取消前一个解析

    final plugin = _sourceRepo.getPluginByName(pluginName);
    if (plugin == null) {
      throw const VideoException(VideoExceptionCode.pluginNotFound);
    }
    if (!plugin.useWebview) return pageUrl;

    _resolveCompleter = Completer<String>();
    await _parsing.init();

    _parserSub = _parsing.onVideoURLParser.listen((event) {
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
      return await _resolveCompleter!.future
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      cancel();
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

  String _cacheKey(String pluginName, String pageUrl) =>
      '$pluginName::$pageUrl';

  void _ensureActive() {
    if (_disposed) {
      throw const VideoException(
        VideoExceptionCode.parseFailed,
        detail: '解析器已释放',
      );
    }
  }
}


