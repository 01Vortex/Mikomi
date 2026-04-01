import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mikomi/features/video/parse/video_webview.dart';

/// 通用 WebView 实现（不支持 DOCUMENT_START_SCRIPT 时的回退方案）
class WebviewFallbackImpl
    extends VideoWebview<InAppWebViewController> {
  HeadlessInAppWebView? headlessWebView;
  bool hasRegisteredHandlers = false;
  bool _useLegacyParser = false;
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
        debugPrint('[WebView] Created (fallback impl)');
        webviewController = controller;
        initEventController.add(true);
      },
      shouldInterceptRequest: (controller, request) async {
        if (_useLegacyParser || isVideoSourceLoaded) return null;
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
        logEventController.add('ServerTrust challenge: ${challenge.protectionSpace.host}');
        return ServerTrustAuthResponse(
          action: ServerTrustAuthResponseAction.PROCEED,
        );
      },
    );
    await headlessWebView?.run();
  }

  @override
  Future<void> loadUrl(String url, bool useLegacyParser,
      {int offset = 0}) async {
    await unloadPage();
    if (!hasRegisteredHandlers) {
      _addJavaScriptHandlers(useLegacyParser);
      hasRegisteredHandlers = true;
    }
    count = 0;
    this.offset = offset;
    _useLegacyParser = useLegacyParser;
    isIframeLoaded = false;
    isVideoSourceLoaded = false;
    videoLoadingEventController.add(true);
    await webviewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  void _addJavaScriptHandlers(bool useLegacyParser) {
    webviewController?.addJavaScriptHandler(
        handlerName: 'LogBridge',
        callback: (args) {
          final message = args.isNotEmpty ? args[0].toString() : '';
          if (message.contains('about:blank')) return;
          logEventController.add(message);
        });
    if (useLegacyParser) {
      webviewController?.addJavaScriptHandler(
          handlerName: 'JSBridgeDebug',
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
          });
    } else {
      webviewController?.addJavaScriptHandler(
          handlerName: 'VideoBridgeDebug',
          callback: (args) {
            final message = args.isNotEmpty ? args[0].toString() : '';
            if (message.contains('http') && !isVideoSourceLoaded) {
              isIframeLoaded = true;
              isVideoSourceLoaded = true;
              videoLoadingEventController.add(false);
              unawaited(unloadPage());
              videoParserEventController.add((message, offset));
            }
          });
    }
  }

  Future<void> _onLoadStart() async {
    if (_useLegacyParser || isVideoSourceLoaded) return;
    await webviewController?.evaluateJavascript(source: """
      (function() {
        function hookFetch(win) {
          try {
            var orig = win.Response.prototype.text;
            win.Response.prototype.text = function() {
              var self = this;
              return orig.call(self).then(function(text) {
                if (text.trim().indexOf('#EXTM3U') === 0)
                  window.flutter_inappwebview.callHandler('VideoBridgeDebug', self.url);
                return text;
              });
            };
          } catch(e) {}
        }
        function hookXHR(win) {
          try {
            var origOpen = win.XMLHttpRequest.prototype.open;
            win.XMLHttpRequest.prototype.open = function() {
              var args = arguments;
              this.addEventListener('load', function() {
                try {
                  if ((this.responseText||'').trim().indexOf('#EXTM3U') === 0)
                    window.flutter_inappwebview.callHandler('VideoBridgeDebug', args[1]);
                } catch(e) {}
              });
              return origOpen.apply(this, args);
            };
          } catch(e) {}
        }
        function injectIframe(iframe) {
          try { var w = iframe.contentWindow; if(!w) return; hookFetch(w); hookXHR(w); } catch(e) {}
        }
        function setupIframes() {
          var iframes = document.querySelectorAll('iframe');
          for(var i=0;i<iframes.length;i++) {
            if(iframes[i].contentDocument) injectIframe(iframes[i]);
            iframes[i].addEventListener('load',(function(f){return function(){injectIframe(f);};})(iframes[i]));
          }
          var obs = new MutationObserver(function(ms) {
            ms.forEach(function(m) {
              m.addedNodes.forEach(function(node) {
                if(node.nodeName==='IFRAME') node.addEventListener('load',function(){injectIframe(node);});
                if(node.querySelectorAll){var fs=node.querySelectorAll('iframe');for(var i=0;i<fs.length;i++)fs[i].addEventListener('load',(function(f){return function(){injectIframe(f);};})(fs[i]));}
              });
            });
          });
          if(document.body) obs.observe(document.body,{childList:true,subtree:true});
          else document.addEventListener('DOMContentLoaded',function(){obs.observe(document.body,{childList:true,subtree:true});});
        }
        hookFetch(window); hookXHR(window);
        if(document.readyState==='loading') document.addEventListener('DOMContentLoaded',setupIframes);
        else setupIframes();
      })();
    """);
  }

  Future<void> _onLoadStop() async {
    if (!_useLegacyParser && !isVideoSourceLoaded) {
      await webviewController?.evaluateJavascript(source: """
        (function() {
          function pv(video) {
            var src=video.getAttribute('src');
            if(src&&src.trim()!==''&&src.indexOf('blob:')!==0&&src.indexOf('googleads')===-1){window.flutter_inappwebview.callHandler('VideoBridgeDebug',src);return true;}
            var ss=video.getElementsByTagName('source');
            for(var i=0;i<ss.length;i++){src=ss[i].getAttribute('src');if(src&&src.trim()!==''&&src.indexOf('blob:')!==0&&src.indexOf('googleads')===-1){window.flutter_inappwebview.callHandler('VideoBridgeDebug',src);return true;}}
            return false;
          }
          var vs=document.querySelectorAll('video');for(var i=0;i<vs.length;i++){if(pv(vs[i]))return;}
          var obs=new MutationObserver(function(ms){
            for(var i=0;i<ms.length;i++){var an=ms[i].addedNodes;for(var j=0;j<an.length;j++){if(an[j].nodeName==='VIDEO'&&pv(an[j]))return;if(an[j].querySelectorAll){var vv=an[j].querySelectorAll('video');for(var k=0;k<vv.length;k++){if(pv(vv[k]))return;}}}}
          });
          if(document.body)obs.observe(document.body,{childList:true,subtree:true,attributes:true,attributeFilter:['src']});
        })();
      """);
    }
    if (_useLegacyParser && !isVideoSourceLoaded) {
      await webviewController?.evaluateJavascript(source: """
        (function() {
          function pi(iframe){var src=iframe.getAttribute('src');if(src)window.flutter_inappwebview.callHandler('JSBridgeDebug',src);}
          var ifs=document.querySelectorAll('iframe');for(var i=0;i<ifs.length;i++)pi(ifs[i]);
          var obs=new MutationObserver(function(ms){ms.forEach(function(m){if(m.type==='attributes'&&m.target.nodeName==='IFRAME')pi(m.target);m.addedNodes.forEach(function(node){if(node.nodeName==='IFRAME')pi(node);if(node.querySelectorAll){var fs=node.querySelectorAll('iframe');for(var i=0;i<fs.length;i++)pi(fs[i]);}});});});
          obs.observe(document.documentElement,{childList:true,subtree:true,attributes:true,attributeFilter:['src']});
        })();
      """);
    }
    _startVideoParserTimer();
  }

  void _startVideoParserTimer() {
    videoParserTimer?.cancel();
    videoParserTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isVideoSourceLoaded) {
        timer.cancel();
        return;
      }
      _pollVideoSource();
    });
  }

  Future<void> _pollVideoSource() async {
    if (isVideoSourceLoaded) return;
    if (_useLegacyParser) {
      await webviewController?.evaluateJavascript(source:
          "(function(){var ifs=document.querySelectorAll('iframe');for(var i=0;i<ifs.length;i++){var src=ifs[i].getAttribute('src');if(src)window.flutter_inappwebview.callHandler('JSBridgeDebug',src);}})();");
    } else {
      await webviewController?.evaluateJavascript(source:
          "(function(){var vs=document.querySelectorAll('video');for(var i=0;i<vs.length;i++){var src=vs[i].getAttribute('src');if(src&&src.trim()!==''&&src.indexOf('blob:')!==0&&src.indexOf('googleads')===-1){window.flutter_inappwebview.callHandler('VideoBridgeDebug',src);return;}}})();");
    }
  }

  @override
  Future<void> unloadPage() async {
    videoParserTimer?.cancel();
    videoParserTimer = null;
    await webviewController
        ?.loadUrl(urlRequest: URLRequest(url: WebUri('about:blank')));
  }

  @override
  void dispose() {
    videoParserTimer?.cancel();
    videoParserTimer = null;
    headlessWebView?.dispose();
    headlessWebView = null;
    webviewController = null;
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
    if (lower.endsWith('.js') || lower.endsWith('.css') || lower.endsWith('.html') ||
        lower.endsWith('.json') || lower.endsWith('.png') || lower.endsWith('.jpg') ||
        lower.endsWith('.gif') || lower.endsWith('.svg') || lower.endsWith('.woff') ||
        lower.endsWith('.woff2') || lower.endsWith('.wasm')) {
      return false;
    }
    return true;
  }

  bool _isAdUrl(String lower) {
    return lower.contains('googleads') || lower.contains('googlesyndication') ||
        lower.contains('adtrafficquality') || lower.contains('doubleclick');
  }

  String _decodeVideoSource(String iframeUrl) {
    final decodedUrl = Uri.decodeFull(iframeUrl);
    final regExp = RegExp(
        r'(http[s]?://.*?\.m3u8)|(http[s]?://.*?\.mp4)',
        caseSensitive: false);
    final uri = Uri.tryParse(decodedUrl);
    if (uri == null) return Uri.encodeFull(decodedUrl);
    String matchedUrl = iframeUrl;
    uri.queryParameters.forEach((key, value) {
      if (regExp.hasMatch(value)) matchedUrl = value;
    });
    return Uri.encodeFull(matchedUrl);
  }
}
