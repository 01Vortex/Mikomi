import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mikomi/features/video/data/services/video_webview_controller.dart';

class VideoWebviewAndroidImpl
    extends VideoWebviewController<InAppWebViewController> {
  HeadlessInAppWebView? headlessWebView;
  bool hasInjectedScripts = false;

  @override
  Future<void> init() async {
    headlessWebView ??= HeadlessInAppWebView(
      initialSettings: InAppWebViewSettings(
        userAgent:
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
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
        debugPrint('[WebView] Created');
        webviewController = controller;
        initEventController.add(true);
      },
      onLoadStart: (controller, url) async {
        logEventController.add('started loading: $url');
      },
      onLoadStop: (controller, url) {
        logEventController.add('loading completed: $url');
      },
    );
    await headlessWebView?.run();
  }

  @override
  Future<void> loadUrl(
    String url,
    bool useLegacyParser, {
    int offset = 0,
  }) async {
    await unloadPage();
    if (!hasInjectedScripts) {
      addJavaScriptHandlers(useLegacyParser);
      await addUserScripts(useLegacyParser);
      hasInjectedScripts = true;
    }
    count = 0;
    this.offset = offset;
    isIframeLoaded = false;
    isVideoSourceLoaded = false;
    videoLoadingEventController.add(true);

    await webviewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  void addJavaScriptHandlers(bool useLegacyParser) {
    logEventController.add('Adding LogBridge handler');
    webviewController?.addJavaScriptHandler(
      handlerName: 'LogBridge',
      callback: (args) {
        String message = args[0].toString();
        if (message.contains('about:blank')) {
          return;
        }
        logEventController.add(message);
      },
    );

    if (useLegacyParser) {
      logEventController.add('Adding JSBridgeDebug handler (Legacy Mode)');
      webviewController?.addJavaScriptHandler(
        handlerName: 'JSBridgeDebug',
        callback: (args) {
          String message = args[0].toString();
          logEventController.add('Callback received: $message');
          if ((message.contains('http') || message.startsWith('//')) &&
              !message.contains('googleads') &&
              !message.contains('googlesyndication.com') &&
              !message.contains('prestrain.html') &&
              !message.contains('prestrain%2Ehtml') &&
              !message.contains('adtrafficquality')) {
            logEventController.add('Parsing video source $message');
            String encodedUrl = Uri.encodeFull(message);
            isIframeLoaded = true;
            isVideoSourceLoaded = true;
            videoLoadingEventController.add(false);
            logEventController.add('Loading video source $encodedUrl');
            unloadPage();
            videoParserEventController.add((encodedUrl, offset));
          }
        },
      );
    } else {
      logEventController.add('Adding VideoBridgeDebug handler (Standard Mode)');
      webviewController?.addJavaScriptHandler(
        handlerName: 'VideoBridgeDebug',
        callback: (args) {
          String message = args[0].toString();
          logEventController.add('Callback received: $message');
          if (message.contains('http') && !isVideoSourceLoaded) {
            logEventController.add('Loading video source: $message');
            isIframeLoaded = true;
            isVideoSourceLoaded = true;
            videoLoadingEventController.add(false);
            unloadPage();
            videoParserEventController.add((message, offset));
          }
        },
      );
    }
  }

  Future<void> addUserScripts(bool useLegacyParser) async {
    final List<UserScript> scripts = [];

    if (useLegacyParser) {
      // Legacy 模式：拦截 iframe
      logEventController.add('Adding JSBridgeDebug UserScript (Legacy Mode)');
      const String jsBridgeDebugScript = """
        window.flutter_inappwebview.callHandler('LogBridge', 'JSBridgeDebug script loaded: ' + window.location.href);
        
        function processIframeElement(iframe) {
          window.flutter_inappwebview.callHandler('LogBridge', 'Processing iframe element');
          let src = iframe.getAttribute('src');
          if (src) {
            window.flutter_inappwebview.callHandler('LogBridge', 'Found iframe src: ' + src);
            window.flutter_inappwebview.callHandler('JSBridgeDebug', src);
          }
        }

        function scanExistingIframes() {
          window.flutter_inappwebview.callHandler('LogBridge', 'Scanning existing iframes...');
          const iframes = document.querySelectorAll('iframe');
          window.flutter_inappwebview.callHandler('LogBridge', 'Found ' + iframes.length + ' iframes');
          iframes.forEach(processIframeElement);
        }

        const _observer = new MutationObserver((mutations) => {
          window.flutter_inappwebview.callHandler('LogBridge', 'Mutation detected, scanning for iframes...');
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
            window.flutter_inappwebview.callHandler('LogBridge', 'DOMContentLoaded event fired');
            scanExistingIframes();
            _observer.observe(document.documentElement, {
              childList: true,
              subtree: true,
              attributes: true,
              attributeFilter: ['src']
            });
          });
        } else {
          window.flutter_inappwebview.callHandler('LogBridge', 'Document already loaded');
          scanExistingIframes();
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
      // 标准模式：拦截 M3U8 和 video 标签
      logEventController.add(
        'Adding VideoBridgeDebug UserScripts (Standard Mode)',
      );

      const String blobParserScript = """
        window.flutter_inappwebview.callHandler('LogBridge', 'BlobParser script loaded: ' + window.location.href);
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
                        window.flutter_inappwebview.callHandler('LogBridge', 'M3U8 source found (XHR): ' + args[1]);
                        window.flutter_inappwebview.callHandler('VideoBridgeDebug', args[1]);
                    };
                } catch {}
            });
            return _open.apply(this, args);
        };
      """;

      const String videoTagParserScript = """
        window.flutter_inappwebview.callHandler('LogBridge', 'VideoTagParser script loaded: ' + window.location.href);
        
        function processVideoElement(video) {
          window.flutter_inappwebview.callHandler('LogBridge', 'Scanning video element for source URL');
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
          window.flutter_inappwebview.callHandler('LogBridge', 'Scanning for video elements...');
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
          window.flutter_inappwebview.callHandler('LogBridge', 'Setting up video processing...');
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
    await webviewController!.loadUrl(
      urlRequest: URLRequest(url: WebUri("about:blank")),
    );
  }

  @override
  void dispose() {
    headlessWebView?.dispose();
    headlessWebView = null;
    webviewController = null;
  }
}
