import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// 全能视频地址解析服务
/// 支持多种视频源格式和解析策略
class WebviewVideoParser {
  HeadlessInAppWebView? _headlessWebView;
  InAppWebViewController? _webviewController;
  bool _hasInjectedScripts = false;
  bool _useLegacyParser = false;
  Timer? _videoParserTimer;
  bool _isDisposed = false;

  int _offset = 0;
  bool _isIframeLoaded = false;
  bool _isVideoSourceLoaded = false;

  final StreamController<String> _logEventController =
      StreamController<String>.broadcast();
  final StreamController<(String, int)> _videoParserEventController =
      StreamController<(String, int)>.broadcast();

  StreamSubscription<(String, int)>? _videoUrlSubscription;
  StreamSubscription<String>? _logSubscription;
  Completer<String>? _videoUrlCompleter;
  Timer? _timeoutTimer;

  /// 解析视频URL
  ///
  /// [pageUrl] 视频页面URL
  /// [useLegacyParser] 是否使用Legacy模式(iframe解析)，false则使用标准模式(video标签解析)
  /// [timeout] 解析超时时间
  /// [maxDepth] 最大递归深度，用于处理多层嵌套的播放器页面
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
      _videoUrlCompleter = Completer<String>();

      debugPrint('========== WebView 视频解析 (深度: $currentDepth) ==========');
      debugPrint('页面URL: $pageUrl');
      debugPrint('使用Legacy模式: $useLegacyParser');
      debugPrint('==================================');

      // 初始化 WebView
      await _init();

      // 订阅日志事件
      _logSubscription = _logEventController.stream.listen((log) {
        debugPrint('[WebView] $log');
      });

      // 订阅视频URL解析事件
      _videoUrlSubscription = _videoParserEventController.stream.listen((
        result,
      ) {
        final (videoUrl, offset) = result;
        debugPrint('========== 视频URL解析成功 ==========');
        debugPrint('视频URL: $videoUrl');
        debugPrint('偏移: $offset');
        debugPrint('==================================');

        if (!_isDisposed &&
            _videoUrlCompleter != null &&
            !_videoUrlCompleter!.isCompleted) {
          _videoUrlCompleter!.complete(videoUrl);
        }
      });

      // 设置超时
      _timeoutTimer = Timer(timeout, () {
        if (_videoUrlCompleter != null && !_videoUrlCompleter!.isCompleted) {
          debugPrint('WebView 解析超时');
          _videoUrlCompleter!.completeError('解析超时');
        }
      });

      // 加载URL
      await _loadUrl(pageUrl, useLegacyParser);

      // 等待解析完成
      final videoUrl = await _videoUrlCompleter!.future;

      // 检查是否需要二次解析
      if (_needsSecondaryParsing(videoUrl) && currentDepth < maxDepth) {
        debugPrint('检测到二级页面,进行二次解析...');
        await dispose();

        // 二次解析使用标准模式(非Legacy),因为要提取真实视频流
        return await _parseVideoUrlRecursive(
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
      await dispose();
    }
  }

  /// 判断URL是否需要二次解析
  bool _needsSecondaryParsing(String url) {
    // 如果是真实的视频流地址,不需要二次解析
    if (url.contains('.m3u8') ||
        url.contains('.mp4') ||
        url.contains('.flv') ||
        url.contains('.ts')) {
      return false;
    }

    // 如果包含这些特征,说明是播放器页面,需要二次解析
    if (url.contains('.html') ||
        url.contains('.php') ||
        url.contains('player') ||
        url.contains('play') ||
        url.contains('index.php')) {
      return true;
    }

    return false;
  }

  Future<void> _init() async {
    _isDisposed = false;
    _headlessWebView ??= HeadlessInAppWebView(
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
        _webviewController = controller;
      },
      shouldInterceptRequest: (controller, request) async {
        if (_isDisposed || _useLegacyParser || _isVideoSourceLoaded) {
          return null;
        }

        final url = request.url.toString();
        final lower = url.toLowerCase();

        if (_isAdUrl(lower)) return null;

        if (_isM3U8Url(lower) || _isRangeVideoRequest(lower, request.headers)) {
          if (!_isDisposed && !_isVideoSourceLoaded) {
            _logEventController.add('原生拦截到视频URL: $url');
            _isIframeLoaded = true;
            _isVideoSourceLoaded = true;
            unawaited(_unloadPage());
            _videoParserEventController.add((url, _offset));
          }
        }
        return null;
      },
      onLoadStart: (controller, url) async {
        if (_isDisposed) return;
        _logEventController.add('started loading: $url');
      },
      onLoadStop: (controller, url) async {
        if (_isDisposed) return;
        _logEventController.add('loading completed: $url');
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
  }

  bool _isAdUrl(String url) {
    return url.contains('googleads') ||
        url.contains('googlesyndication') ||
        url.contains('adtrafficquality') ||
        url.contains('doubleclick');
  }

  bool _isM3U8Url(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.path.toLowerCase().endsWith('.m3u8');
  }

  bool _isRangeVideoRequest(String url, Map<String, String>? headers) {
    if (headers == null) return false;

    final hasRange = headers.keys.any((key) => key.toLowerCase() == 'range');

    if (!hasRange) return false;

    // 排除非视频资源
    final lower = url.toLowerCase();
    if (lower.endsWith('.js') ||
        lower.endsWith('.css') ||
        lower.endsWith('.html') ||
        lower.endsWith('.json') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.svg') ||
        lower.endsWith('.woff') ||
        lower.endsWith('.woff2') ||
        lower.endsWith('.wasm')) {
      return false;
    }

    return true;
  }

  void _startVideoParserTimer() {
    if (_isDisposed) return;
    _videoParserTimer?.cancel();
    _logEventController.add('启动视频解析定时器');

    _videoParserTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || _isVideoSourceLoaded) {
        timer.cancel();
        return;
      }
      _pollVideoSource();
    });
  }

  Future<void> _pollVideoSource() async {
    if (_isDisposed || _isVideoSourceLoaded) return;

    try {
      if (_useLegacyParser) {
        await _webviewController?.evaluateJavascript(
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
        await _webviewController?.evaluateJavascript(
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

  Future<void> _loadUrl(String url, bool useLegacyParser) async {
    if (_isDisposed) return;

    await _unloadPage();
    if (!_hasInjectedScripts) {
      _addJavaScriptHandlers(useLegacyParser);
      await _addUserScripts(useLegacyParser);
      _hasInjectedScripts = true;
    }
    _useLegacyParser = useLegacyParser;
    _isIframeLoaded = false;
    _isVideoSourceLoaded = false;

    if (!_isDisposed) {
      await _webviewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(url)),
      );
    }
  }

  void _addJavaScriptHandlers(bool useLegacyParser) {
    if (_isDisposed) return;

    _logEventController.add('Adding LogBridge handler');
    _webviewController?.addJavaScriptHandler(
      handlerName: 'LogBridge',
      callback: (args) {
        if (_isDisposed) return;
        String message = args[0].toString();
        if (message.contains('about:blank')) return;
        _logEventController.add(message);
      },
    );

    if (useLegacyParser) {
      _logEventController.add('Adding JSBridgeDebug handler (Legacy模式)');
      _webviewController?.addJavaScriptHandler(
        handlerName: 'JSBridgeDebug',
        callback: (args) {
          if (_isDisposed || _isVideoSourceLoaded) return;
          String message = args[0].toString();
          if ((message.contains('http') || message.startsWith('//')) &&
              !message.contains('googleads') &&
              !message.contains('googlesyndication.com') &&
              !message.contains('prestrain.html') &&
              !message.contains('prestrain%2Ehtml') &&
              !message.contains('adtrafficquality')) {
            _logEventController.add('解析iframe源: $message');

            // 从URL参数中提取视频地址
            String videoUrl = _decodeVideoSource(message);

            _isIframeLoaded = true;
            _isVideoSourceLoaded = true;
            _logEventController.add('加载视频源: $videoUrl');
            unawaited(_unloadPage());
            _videoParserEventController.add((videoUrl, _offset));
          }
        },
      );
    } else {
      _logEventController.add('Adding VideoBridgeDebug handler (标准模式)');
      _webviewController?.addJavaScriptHandler(
        handlerName: 'VideoBridgeDebug',
        callback: (args) {
          if (_isDisposed || _isVideoSourceLoaded) return;
          String message = args[0].toString();
          if (message.contains('http') && !message.contains('googleads')) {
            _logEventController.add('加载视频源: $message');
            _isIframeLoaded = true;
            _isVideoSourceLoaded = true;
            unawaited(_unloadPage());
            _videoParserEventController.add((message, _offset));
          }
        },
      );
    }
  }

  /// 从URL参数中解析视频地址
  /// 支持从URL参数中提取m3u8/mp4等视频地址
  String _decodeVideoSource(String iframeUrl) {
    var decodedUrl = Uri.decodeFull(iframeUrl);
    RegExp regExp = RegExp(
      r'(http[s]?://.*?\.m3u8)|(http[s]?://.*?\.mp4)',
      caseSensitive: false,
    );

    Uri uri = Uri.parse(decodedUrl);
    Map<String, String> params = uri.queryParameters;

    String matchedUrl = iframeUrl;
    for (var entry in params.entries) {
      if (regExp.hasMatch(entry.value)) {
        matchedUrl = entry.value;
        break;
      }
    }

    return Uri.encodeFull(matchedUrl);
  }

  Future<void> _addUserScripts(bool useLegacyParser) async {
    if (_isDisposed) return;

    final List<UserScript> scripts = [];

    if (useLegacyParser) {
      // Legacy模式：监听iframe元素
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
      // 标准模式：拦截Fetch/XHR请求中的M3U8
      const String blobParserScript = """
        window.flutter_inappwebview.callHandler('LogBridge', 'BlobParser script loaded');
        
        const _r_text = window.Response.prototype.text;
        window.Response.prototype.text = function () {
            return new Promise((resolve, reject) => {
                _r_text.call(this).then((text) => {
                    resolve(text);
                    if (text.trim().startsWith("#EXTM3U")) {
                        window.flutter_inappwebview.callHandler('LogBridge', 'M3U8 source found: ' + this.url);
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
                        window.flutter_inappwebview.callHandler('LogBridge', 'M3U8 source found: ' + args[1]);
                        window.flutter_inappwebview.callHandler('VideoBridgeDebug', args[1]);
                    };
                } catch {}
            });
            return _open.apply(this, args);
        };

        // 注入到iframe中
        function injectIntoIframe(iframe) {
          try {
            const iframeWindow = iframe.contentWindow;
            if (!iframeWindow) return;

            const iframe_r_text = iframeWindow.Response.prototype.text;
            iframeWindow.Response.prototype.text = function () {
              return new Promise((resolve, reject) => {
                iframe_r_text.call(this).then((text) => {
                  resolve(text);
                  if (text.trim().startsWith("#EXTM3U")) {
                    window.flutter_inappwebview.callHandler('LogBridge', 'M3U8 source found in iframe: ' + this.url);
                    window.flutter_inappwebview.callHandler('VideoBridgeDebug', this.url);
                  }
                }).catch(reject);
              });
            }

            const iframe_open = iframeWindow.XMLHttpRequest.prototype.open;
            iframeWindow.XMLHttpRequest.prototype.open = function (...args) {
              this.addEventListener("load", () => {
                try {
                  let content = this.responseText;
                  if (content.trim().startsWith("#EXTM3U") && args[1] !== null && args[1] !== undefined) {
                    window.flutter_inappwebview.callHandler('LogBridge', 'M3U8 source found in iframe: ' + args[1]);
                    window.flutter_inappwebview.callHandler('VideoBridgeDebug', args[1]);
                  };
                } catch {}
              });
              return iframe_open.apply(this, args);
            }
          } catch (e) {
            console.error('iframe inject failed:', e);
          }
        }

        function setupIframeListeners() {
          document.querySelectorAll('iframe').forEach(iframe => {
            if (iframe.contentDocument) {
              injectIntoIframe(iframe);
            }
            iframe.addEventListener('load', () => injectIntoIframe(iframe));
          });

          const observer = new MutationObserver(mutations => {
            mutations.forEach(mutation => {
              if (mutation.type === 'childList') {
                mutation.addedNodes.forEach(node => {
                  if (node.nodeName === 'IFRAME') {
                    node.addEventListener('load', () => injectIntoIframe(node));
                  }
                  if (node.querySelectorAll) {
                    node.querySelectorAll('iframe').forEach(iframe => {
                      iframe.addEventListener('load', () => injectIntoIframe(iframe));
                    });
                  }
                });
              }
            });
          });

          if (document.body) {
            observer.observe(document.body, { childList: true, subtree: true });
          } else {
            document.addEventListener('DOMContentLoaded', () => {
              observer.observe(document.body, { childList: true, subtree: true });
            });
          }
        }

        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', setupIframeListeners);
        } else {
          setupIframeListeners();
        }
      """;

      // 标准模式：监听video标签
      const String videoTagParserScript = """
        window.flutter_inappwebview.callHandler('LogBridge', 'VideoTagParser script loaded');
        
        function processVideoElement(video) {
          let src = video.getAttribute('src');
          if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.includes('googleads')) {
            window.flutter_inappwebview.callHandler('LogBridge', 'VIDEO source found: ' + src);
            window.flutter_inappwebview.callHandler('VideoBridgeDebug', src);
            _observer.disconnect();
            return true;
          }
          const sources = video.getElementsByTagName('source');
          for (let source of sources) {
            src = source.getAttribute('src');
            if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.includes('googleads')) {
              window.flutter_inappwebview.callHandler('LogBridge', 'VIDEO source found (source tag): ' + src);
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

    await _webviewController?.addUserScripts(userScripts: scripts);
  }

  Future<void> _unloadPage() async {
    _videoParserTimer?.cancel();
    _videoParserTimer = null;
    if (!_isDisposed && _webviewController != null) {
      try {
        await _webviewController?.loadUrl(
          urlRequest: URLRequest(url: WebUri("about:blank")),
        );
      } catch (e) {
        // 忽略unload错误
      }
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
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
