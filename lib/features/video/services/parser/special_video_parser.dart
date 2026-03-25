class SpecialVideoParser {
  static bool shouldUseSpecialMode(String url) {
    final lower = url.toLowerCase();
    return lower.contains('player') || lower.contains('embed') || lower.contains('iframe');
  }

  static const String legacyIframeObserverScript = """
    window.flutter_inappwebview.callHandler('LogBridge', 'Legacy iframe observer loaded');

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

    function setup() {
      document.querySelectorAll('iframe').forEach(processIframeElement);
      _observer.observe(document.documentElement, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ['src']
      });
    }

    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', setup);
    } else {
      setup();
    }
  """;

  static const String legacyIframeProbeScript = """
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
  """;

  static const String playerConfigScanScript = """
    (function() {
      function firstMedia(text) {
        if (!text) return null;
        const reg = /(https?:\\/\\/[^"'\\s]+\\.(m3u8|mpd)(\\?[^"'\\s]*)?)/ig;
        const match = reg.exec(text);
        return match && match[1] ? match[1] : null;
      }

      for (const script of document.querySelectorAll('script')) {
        const url = firstMedia(script.textContent || '');
        if (url) return url;
      }

      try {
        return firstMedia(JSON.stringify(window.__INITIAL_STATE__ || {})) ||
               firstMedia(JSON.stringify(window.__PLAYINFO__ || {})) ||
               firstMedia(JSON.stringify(window.player_aaaa || {}));
      } catch (_) {
        return null;
      }
    })();
  """;
}
