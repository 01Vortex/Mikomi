import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mikomi/features/video/parse/parsing.dart';
import 'package:mikomi/features/video/services/video_parsing_service.dart';

/// 平台 WebView 解析实现
class ParsingIos extends Parsing<InAppWebViewController> {
  HeadlessInAppWebView? headlessWebView;
  bool hasRegisteredHandlers = false;
  bool _useAlternativeParser = false;
  Timer? videoParserTimer;

  @override
  Future<void> init() async {
    headlessWebView ??= HeadlessInAppWebView(
      initialSettings: InAppWebViewSettings(
        userAgent:
            'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Mobile Safari/537.36',
        mediaPlaybackRequiresUserGesture: true,
        upgradeKnownHostsToHTTPS: false,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
        useShouldInterceptRequest: true,
        cacheEnabled: false,
        blockNetworkImage: true,
        loadsImagesAutomatically: false,
      ),
      onWebViewCreated: (controller) {
        debugPrint('[WebView] Created');
        webviewController = controller;
        initEventController.add(true);
      },
      shouldInterceptRequest: (controller, request) async {
        if (_useAlternativeParser || isVideoSourceLoaded) return null;
        final url = request.url.toString();
        final lower = url.toLowerCase();
        if (_isAdUrl(lower)) return null;
        if (_isM3U8Url(lower) || _isRangeVideoRequest(lower, request.headers)) {
          logEventController.add('Native intercepted: $url');
          isIframeLoaded = true;
          isVideoSourceLoaded = true;
          videoLoadingEventController.add(false);
          unawaited(unloadPage());
          videoParserEventController.add((url, offset));
        }
        return null;
      },
      onLoadStart: (controller, url) async {
        logEventController.add('started loading: $url');
        if (url.toString() != 'about:blank') await _onLoadStart();
      },
      onLoadStop: (controller, url) async {
        logEventController.add('loading completed: $url');
        if (url.toString() != 'about:blank') await _onLoadStop();
      },
      onConsoleMessage: (controller, consoleMessage) {
        logEventController.add('Console: ${consoleMessage.message}');
      },
      onReceivedServerTrustAuthRequest: (controller, challenge) async {
        logEventController.add(
          'ServerTrust challenge: ${challenge.protectionSpace.host}',
        );
        return ServerTrustAuthResponse(
          action: ServerTrustAuthResponseAction.PROCEED,
        );
      },
    );
    await headlessWebView?.run();
  }

  @override
  Future<void> loadUrl(
    String url,
    bool useAlternativeParser, {
    int offset = 0,
    VideoStreamResolveOptions options = const VideoStreamResolveOptions(),
  }) async {
    await unloadPage();
    if (!hasRegisteredHandlers) {
      _addJavaScriptHandlers(useAlternativeParser);
      hasRegisteredHandlers = true;
    }
    count = 0;
    this.offset = offset;
    resolveOptions = options;
    _useAlternativeParser = useAlternativeParser;
    isIframeLoaded = false;
    isVideoSourceLoaded = false;
    videoLoadingEventController.add(true);
    await webviewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  void _addJavaScriptHandlers(bool useAlternativeParser) {
    webviewController?.addJavaScriptHandler(
      handlerName: 'ParserLogBridge',
      callback: (args) {
        final message = args.isNotEmpty ? args[0].toString() : '';
        if (message.contains('about:blank')) return;
        logEventController.add(message);
      },
    );
    if (useAlternativeParser) {
      webviewController?.addJavaScriptHandler(
        handlerName: 'ParserCandidateBridge',
        callback: (args) {
          final message = args.isNotEmpty ? args[0].toString() : '';
          if ((message.contains('http') || message.startsWith('//')) &&
              !message.contains('googleads') &&
              !message.contains('googlesyndication.com') &&
              !message.contains('adtrafficquality')) {
            final encodedUrl = Uri.encodeFull(message);
            final decoded = _decodeVideoSource(encodedUrl);
            if (decoded != encodedUrl) {
              isIframeLoaded = true;
              isVideoSourceLoaded = true;
              videoLoadingEventController.add(false);
              unawaited(unloadPage());
              videoParserEventController.add((decoded, offset));
            }
          }
        },
      );
    } else {
      webviewController?.addJavaScriptHandler(
        handlerName: 'ParserStreamBridge',
        callback: (args) {
          final message = args.isNotEmpty ? args[0].toString() : '';
          if (message.contains('http') && !isVideoSourceLoaded) {
            isIframeLoaded = true;
            isVideoSourceLoaded = true;
            videoLoadingEventController.add(false);
            unawaited(unloadPage());
            videoParserEventController.add((message, offset));
          }
        },
      );
    }
  }

  Future<void> _onLoadStart() async {}

  Future<void> _onLoadStop() async {}

  bool _isAdUrl(String lower) {
    return lower.contains('googleads') ||
        lower.contains('googlesyndication') ||
        lower.contains('adtrafficquality');
  }

  bool _isM3U8Url(String lower) {
    final uri = Uri.tryParse(lower);
    if (uri == null) return false;
    return uri.path.endsWith('.m3u8');
  }

  bool _isRangeVideoRequest(String lower, Map<String, String>? headers) {
    if (headers == null) return false;
    final range = headers['Range'] ?? headers['range'];
    if (range == null || !range.startsWith('bytes=')) return false;
    return !(lower.endsWith('.js') ||
        lower.endsWith('.css') ||
        lower.endsWith('.html') ||
        lower.endsWith('.json') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.svg') ||
        lower.endsWith('.woff') ||
        lower.endsWith('.woff2') ||
        lower.endsWith('.wasm'));
  }

  String _decodeVideoSource(String value) {
    return value.startsWith('//') ? 'https:$value' : value;
  }

  @override
  Future<void> unloadPage() async {
    videoParserTimer?.cancel();
    videoParserTimer = null;
    try {
      await webviewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri('about:blank')),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    videoParserTimer?.cancel();
    videoParserTimer = null;
    initEventController.close();
    logEventController.close();
    videoLoadingEventController.close();
    videoParserEventController.close();
    headlessWebView?.dispose();
    headlessWebView = null;
    webviewController = null;
  }
}
