import os

path = r'd:\Code\Mikomi\lib\features\video\services\parser\video_webview_impl.dart'

append = r"""

  Future<void> _onLoadStart() async {
    if (useLegacyParser || isVideoSourceLoaded) return;
    await webviewController?.evaluateJavascript(source: """
      (function() {
        function _hookFetch(win) {
          try {
            const _orig = win.Response.prototype.text;
            win.Response.prototype.text = function () {
              return new Promise((resolve, reject) => {
                _orig.call(this).then((text) => {
                  resolve(text);
                  if (text.trim().startsWith('#EXTM3U')) {
                    window.flutter_inappwebview.callHandler('VideoBridgeDebug', this.url);
                  }
                }).catch(reject);
              });
            };
          } catch(_) {}
        }
        function _hookXHR(win) {
          try {
            const _open = win.XMLHttpRequest.prototype.open;
            win.XMLHttpRequest.prototype.open = function (...args) {
              this.addEventListener('load', () => {
                try {
                  if ((this.responseText||'').trim().startsWith('#EXTM3U')) {
                    window.flutter_inappwebview.callHandler('VideoBridgeDebug', args[1]);
                  }
                } catch (_) {}
              });
              return _open.apply(this, args);
            };
          } catch(_) {}
        }
        function _injectIframe(iframe) {
          try { const w = iframe.contentWindow; if (!w) return; _hookFetch(w); _hookXHR(w); } catch(e) {}
        }
        function _setupIframes() {
          document.querySelectorAll('iframe').forEach(iframe => {
            if (iframe.contentDocument) _injectIframe(iframe);
            iframe.addEventListener('load', () => _injectIframe(iframe));
          });
          const obs = new MutationObserver(mutations => {
            mutations.forEach(m => {
              m.addedNodes.forEach(node => {
                if (node.nodeName === 'IFRAME') node.addEventListener('load', () => _injectIframe(node));
                if (node.querySelectorAll) node.querySelectorAll('iframe').forEach(f => f.addEventListener('load', () => _injectIframe(f)));
              });
            });
          });
          if (document.body) obs.observe(document.body, {childList:true,subtree:true});
          else document.addEventListener('DOMContentLoaded', () => obs.observe(document.body, {childList:true,subtree:true}));
        }
        _hookFetch(window); _hookXHR(window);
        if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', _setupIframes);
        else _setupIframes();
      })();
    """);
  }

  Future<void> _onLoadStop() async {
    if (!useLegacyParser && !isVideoSourceLoaded) {
      await webviewController?.evaluateJavascript(source: """
        (function() {
          function processVideo(video) {
            let src = video.getAttribute('src');
            if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.includes('googleads')) {
              window.flutter_inappwebview.callHandler('VideoBridgeDebug', src); return true;
            }
            for (let s of video.getElementsByTagName('source')) {
              src = s.getAttribute('src');
              if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.includes('googleads')) {
                window.flutter_inappwebview.callHandler('VideoBridgeDebug', src); return true;
              }
            }
            return false;
          }
          for (const v of document.querySelectorAll('video')) { if (processVideo(v)) return; }
          const obs = new MutationObserver(mutations => {
            for (const m of mutations) for (const node of m.addedNodes) {
              if (node.nodeName === 'VIDEO' && processVideo(node)) return;
              if (node.querySelectorAll) for (const v of node.querySelectorAll('video')) { if (processVideo(v)) return; }
            }
          });
          if (document.body) obs.observe(document.body, {childList:true,subtree:true,attributes:true,attributeFilter:['src']});
        })();
      """);
    }
    if (useLegacyParser && !isVideoSourceLoaded) {
      await webviewController?.evaluateJavascript(source: """
        (function() {
          function processIframe(iframe) {
            const src = iframe.getAttribute('src');
            if (src) window.flutter_inappwebview.callHandler('JSBridgeDebug', src);
          }
          document.querySelectorAll('iframe').forEach(processIframe);
          const obs = new MutationObserver(mutations => {
            mutations.forEach(m => {
              if (m.type === 'attributes' && m.target.nodeName === 'IFRAME') processIframe(m.target);
              m.addedNodes.forEach(node => {
                if (node.nodeName === 'IFRAME') processIframe(node);
                if (node.querySelectorAll) node.querySelectorAll('iframe').forEach(processIframe);
              });
            });
          });
          obs.observe(document.documentElement, {childList:true,subtree:true,attributes:true,attributeFilter:['src']});
        })();
      """);
    }
    _startVideoParserTimer();
  }

  void _startVideoParserTimer() {
    videoParserTimer?.cancel();
    videoParserTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isVideoSourceLoaded) { timer.cancel(); return; }
      _pollVideoSource();
    });
  }

  Future<void> _pollVideoSource() async {
    if (isVideoSourceLoaded) return;
    if (useLegacyParser) {
      await webviewController?.evaluateJavascript(source: """
        (function() {
          document.querySelectorAll('iframe').forEach(iframe => {
            const src = iframe.getAttribute('src');
            if (src) window.flutter_inappwebview.callHandler('JSBridgeDebug', src);
          });
        })();
      """);
    } else {
      await webviewController?.evaluateJavascript(source: """
        (function() {
          for (const v of document.querySelectorAll('video')) {
            const src = v.getAttribute('src');
            if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.includes('googleads')) {
              window.flutter_inappwebview.callHandler('VideoBridgeDebug', src); return;
            }
          }
        })();
      """);
    }
  }

  @override
  Future<void> unloadPage() async {
    videoParserTimer?.cancel();
    videoParserTimer = null;
    await webviewController?.loadUrl(urlRequest: URLRequest(url: WebUri('about:blank')));
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
        lower.endsWith('.woff2') || lower.endsWith('.wasm')) return false;
    return true;
  }

  bool _isAdUrl(String lower) {
    return lower.contains('googleads') || lower.contains('googlesyndication') ||
        lower.contains('adtrafficquality') || lower.contains('doubleclick');
  }

  String _decodeVideoSource(String iframeUrl) {
    final decodedUrl = Uri.decodeFull(iframeUrl);
    final regExp = RegExp(r'(http[s]?://.*?\.m3u8)|(http[s]?://.*?\.mp4)', caseSensitive: false);
    final uri = Uri.tryParse(decodedUrl);
    if (uri == null) return Uri.encodeFull(decodedUrl);
    String matchedUrl = iframeUrl;
    uri.queryParameters.forEach((key, value) {
      if (regExp.hasMatch(value)) matchedUrl = value;
    });
    return Uri.encodeFull(matchedUrl);
  }
}
"""

with open(path, 'a', encoding='utf-8') as f:
    f.write(append)
print('Done, appended', len(append), 'chars')
