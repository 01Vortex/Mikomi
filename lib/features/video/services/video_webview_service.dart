import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mikomi/features/video/controller/video_webview_controller.dart';

class VideoWebviewAndroidImpl
    extends VideoWebviewController<InAppWebViewController> {
  HeadlessInAppWebView? headlessWebView;
  bool hasInjectedScripts = false;
  bool useLegacyParser = false;
  Timer? videoParserTimer;
  bool _isDisposed = false;

  @override
  Future<void> init() async {
    _isDisposed = false;
    headlessWebView ??= HeadlessInAppWebView(
      initialSettings: InAppWebViewSettings(
        userAgent:
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        javaScriptEnabled: true,
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
        debugPrint('[WebView] Created');
        webviewController = controller;
        if (!_isDisposed) {
          initEventController.add(true);
        }
      },
      shouldInterceptRequest: (controller, request) async {
        if (_isDisposed || useLegacyParser || isVideoSourceLoaded) return null;

        final url = request.url.toString();
        final lower = url.toLowerCase();

        if (_isAdUrl(lower)) return null;

        if (_isM3U8Url(lower) || _isRangeVideoRequest(lower, request.headers)) {
          if (!_isDisposed && !isVideoSourceLoaded) {
            logEventController.add('原生拦截到视频URL: $url');
            isIframeLoaded = true;
            isVideoSourceLoaded = true;
            videoLoadingEventController.add(false);
            unawaited(unloadPage());
            videoParserEventController.add((url, offset));
          }
        }
        return null;
      },
      onLoadStart: (controller, url) async {
        if (_isDisposed) return;
        logEventController.add('started loading: $url');
        if (url.toString() != 'about:blank') {
          await _onLoadStart();
        }
      },
      onLoadStop: (controller, url) async {
        if (_isDisposed) return;
        logEventController.add('loading completed: $url');
        if (url.toString() != 'about:blank') {
          await _onLoadStop();
        }
      },
      onConsoleMessage: (controller, consoleMessage) {
        if (_isDisposed) return;
        logEventController.add('Console: ${consoleMessage.message}');
      },
    );
    await headlessWebView?.run();
  }

  bool _isAdUrl(String url) {
    return url.contains('googleads') ||
        url.contains('googlesyndication') ||
        url.contains('adtrafficquality') ||
        url.contains('doubleclick');
  }

  bool _isM3U8Url(String url) {
    return url.contains('.m3u8') || url.contains('m3u8');
  }

  bool _isRangeVideoRequest(String url, Map<String, String>? headers) {
    if (headers == null) return false;

    final hasRange = headers.keys.any((key) => key.toLowerCase() == 'range');

    if (!hasRange) return false;

    return url.contains('.mp4') ||
        url.contains('.flv') ||
        url.contains('.ts') ||
        url.contains('.m4s');
  }

  Future<void> _onLoadStart() async {
    // 页面开始加载
  }

  Future<void> _onLoadStop() async {
    if (_isDisposed) return;
    _startVideoParserTimer();
  }

  void _startVideoParserTimer() {
    if (_isDisposed) return;
    videoParserTimer?.cancel();
    logEventController.add('启动视频解析定时器');

    videoParserTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || isVideoSourceLoaded) {
        timer.cancel();
        return;
      }
      _pollVideoSource();
    });
  }

  Future<void> _pollVideoSource() async {
    if (_isDisposed || isVideoSourceLoaded) return;

    try {
      if (useLegacyParser) {
        await webviewController?.evaluateJavascript(
          source: """
          (function() {
            var iframes = document.querySelectorAll('iframe');
            window.flutter_inappwebview.callHandler('LogBridge', '定时扫描: 找到 ' + iframes.length + ' 个iframe');
            for (var i = 0; i < iframes.length; i++) {
              var src = iframes[i].getAttribute('src');
              if (src) {
                window.flutter_inappwebview.callHandler('JSBridgeDebug', src);
              }
            }
          })();
        """,
        );
      } else {
        await webviewController?.evaluateJavascript(
          source: """
          (function() {
            var videos = document.querySelectorAll('video');
            window.flutter_inappwebview.callHandler('LogBridge', '定时扫描: 找到 ' + videos.length + ' 个video');
            for (var i = 0; i < videos.length; i++) {
              var src = videos[i].getAttribute('src');
              if (src && src.trim() !== '' && !src.startsWith('blob:')) {
                window.flutter_inappwebview.callHandler('VideoBridgeDebug', src);
                return;
              }
              var sources = videos[i].getElementsByTagName('source');
              for (var j = 0; j < sources.length; j++) {
                src = sources[j].getAttribute('src');
                if (src && src.trim() !== '' && !src.startsWith('blob:')) {
                  window.flutter_inappwebview.callHandler('VideoBridgeDebug', src);
                  return;
                }
              }
            }
          })();
        """,
        );
      }
    } catch (e) {
      // 忽略轮询错误
    }
  }

  @override
  Future<void> loadUrl(
    String url,
    bool useLegacyParser, {
    int offset = 0,
  }) async {
    if (_isDisposed) return;

    await unloadPage();
    if (!hasInjectedScripts) {
      addJavaScriptHandlers(useLegacyParser);
      await addUserScripts(useLegacyParser);
      hasInjectedScripts = true;
    }
    count = 0;
    this.offset = offset;
    this.useLegacyParser = useLegacyParser;
    isIframeLoaded = false;
    isVideoSourceLoaded = false;

    if (!_isDisposed) {
      videoLoadingEventController.add(true);
      await webviewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(url)),
      );
    }
  }

  void addJavaScriptHandlers(bool useLegacyParser) {
    if (_isDisposed) return;

    logEventController.add('Adding LogBridge handler');
    webviewController?.addJavaScriptHandler(
      handlerName: 'LogBridge',
      callback: (args) {
        if (_isDisposed) return;
        String message = args[0].toString();
        if (message.contains('about:blank')) return;
        logEventController.add(message);
      },
    );

    if (useLegacyParser) {
      logEventController.add('Adding JSBridgeDebug handler');
      webviewController?.addJavaScriptHandler(
        handlerName: 'JSBridgeDebug',
        callback: (args) {
          if (_isDisposed || isVideoSourceLoaded) return;
          String message = args[0].toString();
          if ((message.contains('http') || message.startsWith('//')) &&
              !message.contains('googleads') &&
              !message.contains('googlesyndication.com')) {
            String encodedUrl = Uri.encodeFull(message);
            isIframeLoaded = true;
            isVideoSourceLoaded = true;
            videoLoadingEventController.add(false);
            unawaited(unloadPage());
            videoParserEventController.add((encodedUrl, offset));
          }
        },
      );
    } else {
      logEventController.add('Adding VideoBridgeDebug handler');
      webviewController?.addJavaScriptHandler(
        handlerName: 'VideoBridgeDebug',
        callback: (args) {
          if (_isDisposed || isVideoSourceLoaded) return;
          String message = args[0].toString();
          if (message.contains('http')) {
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

  Future<void> addUserScripts(bool useLegacyParser) async {
    if (_isDisposed) return;

    final List<UserScript> scripts = [];

    if (useLegacyParser) {
      const String jsBridgeDebugScript = """
        window.flutter_inappwebview.callHandler('LogBridge', 'JSBridgeDebug script loaded');
        
        function processIframeElement(iframe) {
          let src = iframe.getAttribute('src');
          if (src) {
            window.flutter_inappwebview.callHandler('JSBridgeDebug', src);
          }
        }

        const _observer = new MutationObserver((mutations) => {
          mutations.forEach(mutation => {
            if (mutation.type === 'attributes' && mutation.target.nodeName === 'IFRAME') {
              processIframeElement(mutation.target);
            } else {
              mutation.addedNodes.forEach(node => {
                if (node.nodeName === 'IFRAME') processIframeElement(node);
                if (node.querySelectorAll) {
                  node.querySelectorAll('iframe').forEach(processIframeElement);
                }
              });
            }
          });  
        });

        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', function() {
            document.querySelectorAll('iframe').forEach(processIframeElement);
            _observer.observe(document.documentElement, {
              childList: true,
              subtree: true,
              attributes: true,
              attributeFilter: ['src']
            });
          });
        } else {
          document.querySelectorAll('iframe').forEach(processIframeElement);
          _observer.observe(document.documentElement, {
            childList: true,
            subtree: true,
            attributes: true,
            attributeFilter: ['src']
          });
        }
      """;
      scripts.add(
        UserScript(
          source: jsBridgeDebugScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );
    } else {
      const String blobParserScript = """
        const _r_text = window.Response.prototype.text;
        window.Response.prototype.text = function () {
            return new Promise((resolve, reject) => {
                _r_text.call(this).then((text) => {
                    resolve(text);
                    if (text.trim().startsWith("#EXTM3U")) {
                        window.flutter_inappwebview.callHandler('VideoBridgeDebug', this.url);
                    }
                }).catch(reject);
            });
        }

        const _open = window.XMLHttpRequest.prototype.open;
        window.XMLHttpRequest.prototype.open = function (...args) {
            this.addEventListener("load", () => {
                try {
                    let content = this.responseText;
                    if (content.trim().startsWith("#EXTM3U")) {
                        window.flutter_inappwebview.callHandler('VideoBridgeDebug', args[1]);
                    };
                } catch {}
            });
            return _open.apply(this, args);
        };
      """;

      const String videoTagParserScript = """
        function processVideoElement(video) {
          let src = video.getAttribute('src');
          if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.includes('googleads')) {
            window.flutter_inappwebview.callHandler('VideoBridgeDebug', src);
            _observer.disconnect();
            return true;
          }
          const sources = video.getElementsByTagName('source');
          for (let source of sources) {
            src = source.getAttribute('src');
            if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.includes('googleads')) {
              window.flutter_inappwebview.callHandler('VideoBridgeDebug', src);
              _observer.disconnect();
              return true;
            }
          }
          return false;
        }
        
        const _observer = new MutationObserver((mutations) => {
          for (const mutation of mutations) {
            if (mutation.type === "attributes" && mutation.target.nodeName === "VIDEO") {
              if (processVideoElement(mutation.target)) return;
              continue;
            }
            for (const node of mutation.addedNodes) {
              if (node.nodeName === "VIDEO") {
                if (processVideoElement(node)) return;
              }
              if (node.querySelectorAll) {
                for (const video of node.querySelectorAll("video")) {
                  if (processVideoElement(video)) return;
                }
              }
            }
          }
        });

        function setupVideoProcessing() {
          for (const video of document.querySelectorAll("video")) {
            if (processVideoElement(video)) return;
          }
          _observer.observe(document.body, {
            childList: true,
            subtree: true,
            attributes: true,
            attributeFilter: ['src']
          });
        }
        
        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', setupVideoProcessing);
        } else {
          setupVideoProcessing();
        }
      """;

      scripts.add(
        UserScript(
          source: blobParserScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );
      scripts.add(
        UserScript(
          source: videoTagParserScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );
    }

    await webviewController?.addUserScripts(userScripts: scripts);
  }

  @override
  Future<void> unloadPage() async {
    videoParserTimer?.cancel();
    videoParserTimer = null;
    if (!_isDisposed && webviewController != null) {
      try {
        await webviewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri("about:blank")),
        );
      } catch (e) {
        // 忽略unload错误
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    videoParserTimer?.cancel();
    videoParserTimer = null;
    headlessWebView?.dispose();
    headlessWebView = null;
    webviewController = null;
  }
}
