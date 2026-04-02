import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/anti_anti_crawler.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/anti_anti_crawler_composite.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/captcha_handler.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/cookie_manager.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/error_retry.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/fingerprint_spoofer.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/js_hook.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/proxy_strategy.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/request_delay.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/request_interceptor.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/resource_filter.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/ua_dynamic_generation.dart';
import 'package:mikomi/features/video/parse/anti_anti_crawler/webdriver_hider.dart';
import 'package:mikomi/features/video/parse/parsing.dart';

/// 平台 WebView 解析实现
class ParsingAndroid
    extends Parsing<InAppWebViewController> {
  HeadlessInAppWebView? headlessWebView;
  bool hasInjectedScripts = false;

  final UaDynamicGeneration _uaDynamicGeneration = UaDynamicGeneration();
  final RequestInterceptor _requestInterceptor = const RequestInterceptor();
  final ResourceFilter _resourceFilter = const ResourceFilter();
  final RequestDelay _requestDelay = const RequestDelay();
  final ProxyStrategy _proxyStrategy = const ProxyStrategy();
  final ParsingCookieManager _cookieManager = ParsingCookieManager();
  final CaptchaHandler _captchaHandler = const CaptchaHandler();
  final ErrorRetry _errorRetry = const ErrorRetry();
  late final CompositeAntiAntiCrawler _antiAntiCrawler =
      CompositeAntiAntiCrawler(const [
        WebdriverHider(),
        FingerprintSpoofer(),
        JsHook(),
      ]);

  @override
  Future<void> init() async {
    headlessWebView ??= HeadlessInAppWebView(
      initialSettings: InAppWebViewSettings(
        userAgent: _uaDynamicGeneration.generate(),
        mediaPlaybackRequiresUserGesture: true,
        cacheEnabled: false,
        blockNetworkImage: true,
        loadsImagesAutomatically: false,
        upgradeKnownHostsToHTTPS: false,
        safeBrowsingEnabled: false,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
        geolocationEnabled: false,
        useShouldInterceptRequest: true,
      ),
      onWebViewCreated: (controller) {
        debugPrint('[WebView] Created');
        webviewController = controller;
        initEventController.add(true);
      },
      shouldInterceptRequest: (controller, request) async {
        if (isVideoSourceLoaded) return null;
        final url = request.url.toString();
        final lower = url.toLowerCase();
        if (!_requestInterceptor.shouldAllow(lower)) return null;
        if (!_resourceFilter.allow(lower)) return null;
        if (_isM3U8Url(lower) || _isRangeVideoRequest(lower, request.headers)) {
          _onPotentialVideoRequest(url);
        }
        return null;
      },
      onLoadStart: (controller, url) async {
        logEventController.add('started loading: $url');
      },
      onLoadStop: (controller, url) async {
        logEventController.add('loading completed: $url');
        await _runAfterLoadStrategies(url?.toString() ?? '');
      },
      onConsoleMessage: (controller, consoleMessage) {
        logEventController.add('Console: ${consoleMessage.message}');
      },
      onReceivedServerTrustAuthRequest: (controller, challenge) async {
        logEventController
            .add('ServerTrust challenge: ${challenge.protectionSpace.host}');
        return ServerTrustAuthResponse(
          action: ServerTrustAuthResponseAction.PROCEED,
        );
      },
    );
    await headlessWebView?.run();
  }

  @override
  Future<void> loadUrl(String url, bool useAlternativeParser,
      {int offset = 0}) async {
    await unloadPage();
    if (!hasInjectedScripts) {
      _addJavaScriptHandlers(useAlternativeParser);
      await _addUserScripts(useAlternativeParser);
      hasInjectedScripts = true;
    }
    count = 0;
    this.offset = offset;
    isIframeLoaded = false;
    isVideoSourceLoaded = false;
    videoLoadingEventController.add(true);
    await _runBeforeLoadStrategies(url, useAlternativeParser, offset);
    await Future.delayed(_requestDelay.nextDelay());
    await webviewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
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
    if (lower.endsWith('.js') || lower.endsWith('.css') ||
        lower.endsWith('.html') || lower.endsWith('.json') ||
        lower.endsWith('.png') || lower.endsWith('.jpg') ||
        lower.endsWith('.gif') || lower.endsWith('.svg') ||
        lower.endsWith('.woff') || lower.endsWith('.woff2') ||
        lower.endsWith('.wasm')) {
      return false;
    }
    return true;
  }

  bool _isAdUrl(String lower) {
    return lower.contains('googleads') ||
        lower.contains('googlesyndication') ||
        lower.contains('adtrafficquality') ||
        lower.contains('doubleclick');
  }

  void _onPotentialVideoRequest(String url) {
    if (isVideoSourceLoaded) return;
    isIframeLoaded = true;
    isVideoSourceLoaded = true;
    videoLoadingEventController.add(false);
    logEventController.add('Native intercepted video source: $url');
    unawaited(unloadPage());
    videoParserEventController.add((url, offset));
  }

  void _addJavaScriptHandlers(bool useAlternativeParser) {
    logEventController.add('Adding ParserLogBridge handler');
    webviewController?.addJavaScriptHandler(
        handlerName: 'ParserLogBridge',
        callback: (args) {
          final message = args.isNotEmpty ? args[0].toString() : '';
          if (message.contains('about:blank')) return;
          logEventController.add(message);
        });
    if (useAlternativeParser) {
      logEventController.add('Adding ParserCandidateBridge handler');
      webviewController?.addJavaScriptHandler(
          handlerName: 'ParserCandidateBridge',
          callback: (args) {
            final message = args.isNotEmpty ? args[0].toString() : '';
            logEventController.add('Callback received: $message');
            if ((message.contains('http') || message.startsWith('//')) &&
                !message.contains('googleads') &&
                !message.contains('googlesyndication.com') &&
                !message.contains('prestrain.html') &&
                !message.contains('prestrain%2Ehtml') &&
                !message.contains('adtrafficquality')) {
              final encodedUrl = Uri.encodeFull(message);
              final decoded = _decodeVideoSource(encodedUrl);
              if (decoded != encodedUrl) {
                isIframeLoaded = true;
                isVideoSourceLoaded = true;
                videoLoadingEventController.add(false);
                logEventController.add('Loading video source $decoded');
                unawaited(unloadPage());
                videoParserEventController.add((decoded, offset));
              }
            }
          });
    } else {
      logEventController.add('Adding ParserStreamBridge handler');
      webviewController?.addJavaScriptHandler(
          handlerName: 'ParserStreamBridge',
          callback: (args) {
            final message = args.isNotEmpty ? args[0].toString() : '';
            logEventController.add('Callback received: $message');
            if (message.contains('http') && !isVideoSourceLoaded) {
              logEventController.add('Loading video source: $message');
              isIframeLoaded = true;
              isVideoSourceLoaded = true;
              videoLoadingEventController.add(false);
              unawaited(unloadPage());
              videoParserEventController.add((message, offset));
            }
          });
    }
  }

  Future<void> _addUserScripts(bool useAlternativeParser) async {
    final scripts = <UserScript>[];
    if (useAlternativeParser) {
      logEventController.add('Adding ParserCandidateBridge UserScript');
      const String parserCandidateScript = """
        window.flutter_inappwebview.callHandler('ParserLogBridge', 'ParserCandidateBridge script loaded: ' + window.location.href);
        function processIframeElement(iframe) {
          let src = iframe.getAttribute('src');
          if (src) { window.flutter_inappwebview.callHandler('ParserCandidateBridge', src); }
        }
        const _observer = new MutationObserver((mutations) => {
          mutations.forEach(mutation => {
            if (mutation.type === 'attributes' && mutation.target.nodeName === 'IFRAME') {
              processIframeElement(mutation.target);
            } else {
              mutation.addedNodes.forEach(node => {
                if (node.nodeName === 'IFRAME') processIframeElement(node);
                if (node.querySelectorAll) { node.querySelectorAll('iframe').forEach(processIframeElement); }
              });
            }
          });
        });
        _observer.observe(document.documentElement, { childList: true, subtree: true, attributes: true, attributeFilter: ['src'] });
      """;
      scripts.add(UserScript(
        source: parserCandidateScript,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
      ));
    } else {
      logEventController.add('Adding ParserStreamBridge UserScripts');
      const String blobParserScript = """
        window.flutter_inappwebview.callHandler('ParserLogBridge', 'BlobParser script loaded: ' + window.location.href);
        function _hookWindowFetch(win) {
          try {
            const _r_text = win.Response.prototype.text;
            win.Response.prototype.text = function () {
              return new Promise((resolve, reject) => {
                _r_text.call(this).then((text) => {
                  resolve(text);
                  if (text.trim().startsWith('#EXTM3U')) {
                    window.flutter_inappwebview.callHandler('ParserLogBridge', 'M3U8 source found: ' + this.url);
                    window.flutter_inappwebview.callHandler('ParserStreamBridge', this.url);
                  }
                }).catch(reject);
              });
            };
          } catch(_) {}
        }
        function _hookWindowXHR(win) {
          try {
            const _open = win.XMLHttpRequest.prototype.open;
            win.XMLHttpRequest.prototype.open = function (...args) {
              this.addEventListener('load', () => {
                try {
                  const content = this.responseText || '';
                  if (content.trim().startsWith('#EXTM3U')) {
                    window.flutter_inappwebview.callHandler('ParserLogBridge', 'M3U8 source found: ' + args[1]);
                    window.flutter_inappwebview.callHandler('ParserStreamBridge', args[1]);
                  }
                } catch (_) {}
              });
              return _open.apply(this, args);
            };
          } catch(_) {}
        }
        function _injectIntoIframe(iframe) {
          try { const w = iframe.contentWindow; if (!w) return; _hookWindowFetch(w); _hookWindowXHR(w); } catch(e) {}
        }
        function _setupIframeListeners() {
          document.querySelectorAll('iframe').forEach(iframe => {
            if (iframe.contentDocument) _injectIntoIframe(iframe);
            iframe.addEventListener('load', () => _injectIntoIframe(iframe));
          });
          const observer = new MutationObserver(mutations => {
            mutations.forEach(mutation => {
              mutation.addedNodes.forEach(node => {
                if (node.nodeName === 'IFRAME') { node.addEventListener('load', () => _injectIntoIframe(node)); }
                if (node.querySelectorAll) { node.querySelectorAll('iframe').forEach(f => { f.addEventListener('load', () => _injectIntoIframe(f)); }); }
              });
            });
          });
          if (document.body) { observer.observe(document.body, { childList: true, subtree: true }); }
          else { document.addEventListener('DOMContentLoaded', () => { observer.observe(document.body, { childList: true, subtree: true }); }); }
        }
        _hookWindowFetch(window); _hookWindowXHR(window);
        if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', _setupIframeListeners); }
        else { _setupIframeListeners(); }
      """;
      const String videoTagParserScript = """
        window.flutter_inappwebview.callHandler('ParserLogBridge', 'VideoTagParser script loaded: ' + window.location.href);
        const _observer = new MutationObserver((mutations) => {
          for (const mutation of mutations) {
            if (mutation.type === 'attributes' && mutation.target.nodeName === 'VIDEO') { if (processVideoElement(mutation.target)) return; continue; }
            for (const node of mutation.addedNodes) {
              if (node.nodeName === 'VIDEO') { if (processVideoElement(node)) return; }
              if (node.querySelectorAll) { for (const v of node.querySelectorAll('video')) { if (processVideoElement(v)) return; } }
            }
          }
        });
        function processVideoElement(video) {
          let src = video.getAttribute('src');
          if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.includes('googleads')) {
            _observer.disconnect();
            window.flutter_inappwebview.callHandler('ParserStreamBridge', src);
            return true;
          }
          for (let s of video.getElementsByTagName('source')) {
            src = s.getAttribute('src');
            if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.includes('googleads')) {
              _observer.disconnect();
              window.flutter_inappwebview.callHandler('ParserStreamBridge', src);
              return true;
            }
          }
          return false;
        }
        function setupVideoProcessing() {
          for (const v of document.querySelectorAll('video')) { if (processVideoElement(v)) return; }
          _observer.observe(document.body, { childList: true, subtree: true, attributes: true, attributeFilter: ['src'] });
        }
        if (document.readyState === 'loading') { document.addEventListener('DOMContentLoaded', setupVideoProcessing); }
        else { setupVideoProcessing(); }
      """;
      scripts.add(UserScript(source: blobParserScript, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START));
      scripts.add(UserScript(source: videoTagParserScript, injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START));
    }
    await webviewController?.addUserScripts(userScripts: scripts);
  }

  Future<void> _runBeforeLoadStrategies(
    String requestUrl,
    bool useAlternativeParser,
    int offset,
  ) async {
    final context = AntiAntiCrawlerContext(
      controller: webviewController,
      requestUrl: requestUrl,
      useAlternativeParser: useAlternativeParser,
      offset: offset,
    );
    _proxyStrategy.nextProxy();
    _cookieManager.save('last_request_url', requestUrl);
    await _antiAntiCrawler.onBeforeLoad(context);
  }

  Future<void> _runAfterLoadStrategies(String requestUrl) async {
    final context = AntiAntiCrawlerContext(
      controller: webviewController,
      requestUrl: requestUrl,
      useAlternativeParser: false,
      offset: offset,
    );
    await _antiAntiCrawler.onAfterLoad(context);

    final html = await webviewController?.evaluateJavascript(
      source: 'document.documentElement ? document.documentElement.outerHTML : "";',
    );
    final htmlText = html?.toString() ?? '';
    if (_captchaHandler.detect(htmlText)) {
      final shouldRetry = _errorRetry.shouldRetry(count);
      logEventController.add('captcha detected, shouldRetry=$shouldRetry');
      if (shouldRetry) {
        count++;
      }
    }
  }

  @override
  Future<void> unloadPage() async {
    await webviewController
        ?.loadUrl(urlRequest: URLRequest(url: WebUri('about:blank')));
  }

  @override
  void dispose() {
    _antiAntiCrawler.dispose();
    _cookieManager.clear();
    headlessWebView?.dispose();
    headlessWebView = null;
    webviewController = null;
  }

  String _decodeVideoSource(String iframeUrl) {
    final decodedUrl = Uri.decodeFull(iframeUrl);
    final regExp = RegExp(
      r'(http[s]?://.*?\.m3u8)|(http[s]?://.*?\.mp4)',
      caseSensitive: false,
    );
    final uri = Uri.tryParse(decodedUrl);
    if (uri == null) return Uri.encodeFull(decodedUrl);
    String matchedUrl = iframeUrl;
    uri.queryParameters.forEach((key, value) {
      if (regExp.hasMatch(value)) matchedUrl = value;
    });
    return Uri.encodeFull(matchedUrl);
  }
}
