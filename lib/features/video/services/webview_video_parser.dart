import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mikomi/features/video/services/parser/anti_anti_crawler.dart';
import 'package:mikomi/features/video/services/parser/video_source_provider.dart'
    show VideoSourceCancelledException;
import 'package:mikomi/features/video/services/parser/general_video_parser.dart';
import 'package:mikomi/features/video/services/parser/special_video_parser.dart';

/// 视频地址解析服务（编排层）
///
/// - 通用解析: `GeneralVideoParser`
/// - 特殊解析: `SpecialVideoParser`
/// - 反反爬: `AntiAntiCrawler`
class WebviewVideoParser {
  HeadlessInAppWebView? _headlessWebView;
  InAppWebViewController? _webviewController;

  bool _hasInjectedScripts = false;
  bool _useLegacyParser = false;
  bool _isDisposed = false;
  bool _isInitializing = false;
  bool _isVideoSourceLoaded = false;

  int _activeSessionId = 0;
  final int _offset = 0;

  String? _currentPageUrl;
  String? _previousPageUrl;
  String? _cookieHeader;

  Timer? _videoParserTimer;
  Timer? _timeoutTimer;

  final StreamController<String> _logEventController =
      StreamController<String>.broadcast();
  final StreamController<(String, int)> _videoParserEventController =
      StreamController<(String, int)>.broadcast();

  StreamSubscription<String>? _logSubscription;
  StreamSubscription<(String, int)>? _videoUrlSubscription;
  Completer<String>? _videoUrlCompleter;

  Future<String?> parseVideoUrl(
    String pageUrl, {
    bool useLegacyParser = true,
    Duration timeout = const Duration(seconds: 45),
    int maxDepth = 3,
  }) async {
    return _parseVideoUrlRecursive(
      pageUrl,
      useLegacyParser: useLegacyParser,
      timeout: timeout,
      currentDepth: 0,
      maxDepth: maxDepth,
    );
  }

  Future<String?> _parseVideoUrlRecursive(
    String pageUrl, {
    required bool useLegacyParser,
    required Duration timeout,
    required int currentDepth,
    required int maxDepth,
  }) async {
    try {
      _isDisposed = false;
      final sessionId = ++_activeSessionId;
      _videoUrlCompleter = Completer<String>();

      _cookieHeader = await AntiAntiCrawler.readCookiesForUrl(pageUrl);

      await _init();
      _registerListeners(sessionId, timeout);
      await _loadUrl(pageUrl, useLegacyParser);

      final videoUrl = await _videoUrlCompleter!.future;

      if (GeneralVideoParser.needsSecondaryParsing(videoUrl) &&
          currentDepth < maxDepth) {
        await dispose();
        return _parseVideoUrlRecursive(
          videoUrl,
          useLegacyParser: false,
          timeout: timeout,
          currentDepth: currentDepth + 1,
          maxDepth: maxDepth,
        );
      }

      return videoUrl;
    } catch (e) {
      debugPrint('WebView 解析失败: $e');
      return null;
    } finally {
      await _cleanupAfterParse();
    }
  }

  void _registerListeners(int sessionId, Duration timeout) {
    _logSubscription = _logEventController.stream.listen((log) {
      debugPrint('[WebView] $log');
    });

    _videoUrlSubscription = _videoParserEventController.stream.listen((result) {
      final (videoUrl, offset) = result;
      debugPrint('视频URL解析成功: $videoUrl, offset=$offset');
      if (!_isDisposed &&
          sessionId == _activeSessionId &&
          _videoUrlCompleter != null &&
          !_videoUrlCompleter!.isCompleted) {
        _videoUrlCompleter!.complete(videoUrl);
      }
    });

    _timeoutTimer = Timer(timeout, () {
      if (!_isDisposed &&
          sessionId == _activeSessionId &&
          _videoUrlCompleter != null &&
          !_videoUrlCompleter!.isCompleted) {
        _videoUrlCompleter!.completeError('解析超时');
      }
    });
  }

  Future<void> _init() async {
    if (_isInitializing) return;
    _isInitializing = true;

    _headlessWebView ??= HeadlessInAppWebView(
      initialSettings: InAppWebViewSettings(
        userAgent:
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        javaScriptEnabled: true,
        javaScriptCanOpenWindowsAutomatically: true,
        useShouldInterceptRequest: true,
        mediaPlaybackRequiresUserGesture: false,
        cacheEnabled: false,
        clearCache: true,
        blockNetworkImage: true,
        loadsImagesAutomatically: false,
        upgradeKnownHostsToHTTPS: false,
        safeBrowsingEnabled: false,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        geolocationEnabled: false,
      ),
      onWebViewCreated: (controller) {
        if (_isDisposed) return;
        _webviewController = controller;
      },
      shouldInterceptRequest: (controller, request) async {
        if (_isDisposed || _useLegacyParser || _isVideoSourceLoaded) {
          return null;
        }

        final url = request.url.toString();
        if (AntiAntiCrawler.isAdUrl(url)) return null;

        if (GeneralVideoParser.looksLikePlayableMedia(url) ||
            GeneralVideoParser.isM3U8Url(url) ||
            GeneralVideoParser.isRangeVideoRequest(url, request.headers)) {
          _emitResolvedUrl(url);
        }
        return null;
      },
      onLoadStart: (controller, url) async {
        if (_isDisposed) return;
        if (url != null && url.toString() != 'about:blank') {
          _previousPageUrl = _currentPageUrl;
          _currentPageUrl = url.toString();
        }
        _logEventController.add('started loading: $url');
      },
      onLoadStop: (controller, url) async {
        if (_isDisposed) return;
        if (url.toString() != 'about:blank') {
          _startVideoParserTimer();
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        if (_isDisposed) return;
        _logEventController.add('Console: ${consoleMessage.message}');
      },
    );

    await _headlessWebView?.run();
    _isInitializing = false;
  }

  void _emitResolvedUrl(String rawUrl) {
    if (_isDisposed || _isVideoSourceLoaded) return;
    _isVideoSourceLoaded = true;

    final normalized = GeneralVideoParser.normalizePossibleUrl(
      rawUrl,
      _currentPageUrl,
    );

    unawaited(_unloadPage());
    _videoParserEventController.add((normalized, _offset));
  }

  void _startVideoParserTimer() {
    _videoParserTimer?.cancel();
    _videoParserTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || _isVideoSourceLoaded) {
        timer.cancel();
        return;
      }
      _pollVideoSource();
      _scanPlayerConfigForMedia();
    });
  }

  Future<void> _pollVideoSource() async {
    if (_isDisposed || _isVideoSourceLoaded) return;

    try {
      if (_useLegacyParser) {
        await _webviewController?.evaluateJavascript(
          source: SpecialVideoParser.legacyIframeProbeScript,
        );
      } else {
        await _webviewController?.evaluateJavascript(
          source: """
          (function() {
            const videos = document.querySelectorAll('video');
            for (let i = 0; i < videos.length; i++) {
              let src = videos[i].currentSrc || videos[i].getAttribute('src');
              if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.startsWith('data:')) {
                window.flutter_inappwebview.callHandler('VideoBridgeDebug', src);
                return;
              }
              const sources = videos[i].getElementsByTagName('source');
              for (let j = 0; j < sources.length; j++) {
                src = sources[j].getAttribute('src');
                if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.startsWith('data:')) {
                  window.flutter_inappwebview.callHandler('VideoBridgeDebug', src);
                  return;
                }
              }
            }
          })();
        """,
        );
      }
    } catch (_) {}
  }

  Future<void> _scanPlayerConfigForMedia() async {
    if (_isDisposed || _isVideoSourceLoaded || _webviewController == null) {
      return;
    }

    try {
      final result = await _webviewController!.evaluateJavascript(
        source: SpecialVideoParser.playerConfigScanScript,
      );
      if (result is String && result.isNotEmpty) {
        _emitResolvedUrl(result);
      }
    } catch (_) {}
  }

  Future<void> _loadUrl(String url, bool useLegacyParser) async {
    if (_isDisposed) return;

    await _unloadPage();

    if (!_hasInjectedScripts) {
      _addJavaScriptHandlers(useLegacyParser);
      await _addUserScripts(useLegacyParser);
      _hasInjectedScripts = true;
    }

    _useLegacyParser = useLegacyParser;
    _isVideoSourceLoaded = false;

    await _webviewController?.loadUrl(
      urlRequest: URLRequest(
        url: WebUri(url),
        headers: AntiAntiCrawler.buildRequestHeaders(
          url,
          currentPageUrl: _currentPageUrl,
          previousPageUrl: _previousPageUrl,
          cookieHeader: _cookieHeader,
        ),
      ),
    );
  }

  void _addJavaScriptHandlers(bool useLegacyParser) {
    _webviewController?.addJavaScriptHandler(
      handlerName: 'LogBridge',
      callback: (args) {
        if (_isDisposed) return;
        final message = args.isNotEmpty ? args[0].toString() : '';
        if (message.contains('about:blank')) return;
        _logEventController.add(message);
      },
    );

    _webviewController?.addJavaScriptHandler(
      handlerName: 'JSBridgeDebug',
      callback: (args) {
        if (_isDisposed || _isVideoSourceLoaded || !useLegacyParser) return;
        final message = args.isNotEmpty ? args[0].toString() : '';
        if ((message.contains('http') || message.startsWith('//')) &&
            !AntiAntiCrawler.isAdUrl(message)) {
          final videoUrl = GeneralVideoParser.decodeVideoSource(message);
          _emitResolvedUrl(videoUrl);
        }
      },
    );

    _webviewController?.addJavaScriptHandler(
      handlerName: 'VideoBridgeDebug',
      callback: (args) {
        if (_isDisposed || _isVideoSourceLoaded || useLegacyParser) return;
        final message = args.isNotEmpty ? args[0].toString() : '';
        if (GeneralVideoParser.looksLikePlayableMedia(message) ||
            message.contains('http')) {
          _emitResolvedUrl(message);
        }
      },
    );
  }

  Future<void> _addUserScripts(bool useLegacyParser) async {
    final scripts = <UserScript>[];

    if (useLegacyParser) {
      scripts.add(
        UserScript(
          source: SpecialVideoParser.legacyIframeObserverScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );
    } else {
      scripts.add(
        UserScript(
          source: AntiAntiCrawler.blobAndXhrHookScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );
      scripts.add(
        UserScript(
          source: GeneralVideoParser.videoTagParserScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );
    }

    await _webviewController?.addUserScripts(userScripts: scripts);
  }

  Future<void> _unloadPage() async {
    _videoParserTimer?.cancel();
    _videoParserTimer = null;

    if (_webviewController != null && !_isDisposed) {
      try {
        await _webviewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri('about:blank')),
        );
      } catch (_) {}
    }
  }

  Future<void> _cleanupAfterParse() async {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    await _logSubscription?.cancel();
    _logSubscription = null;

    await _videoUrlSubscription?.cancel();
    _videoUrlSubscription = null;

    _videoParserTimer?.cancel();
    _videoParserTimer = null;

    _videoUrlCompleter = null;

    await _unloadPage();
  }

  void cancelCurrentParse() {
    _activeSessionId++;

    if (_videoUrlCompleter != null && !_videoUrlCompleter!.isCompleted) {
      _videoUrlCompleter!.completeError(const VideoSourceCancelledException());
    }

    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _videoParserTimer?.cancel();
    _videoParserTimer = null;

    unawaited(_unloadPage());
  }

  Future<void> dispose() async {
    _activeSessionId++;
    _isDisposed = true;
    _isInitializing = false;

    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    await _logSubscription?.cancel();
    _logSubscription = null;

    await _videoUrlSubscription?.cancel();
    _videoUrlSubscription = null;

    _videoParserTimer?.cancel();
    _videoParserTimer = null;

    _headlessWebView?.dispose();
    _headlessWebView = null;
    _webviewController = null;

    _videoUrlCompleter = null;
  }
}
