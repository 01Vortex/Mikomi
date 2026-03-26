import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AntiAntiCrawler {
  static bool isAdUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('googleads') ||
        lower.contains('googlesyndication') ||
        lower.contains('adtrafficquality') ||
        lower.contains('doubleclick');
  }

  static Future<String?> readCookiesForUrl(String url) async {
    try {
      final cookies = await CookieManager.instance().getCookies(url: WebUri(url));
      if (cookies.isEmpty) return null;
      return cookies.map((c) => '${c.name}=${c.value}').join('; ');
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> buildRequestHeaders(
    String targetUrl, {
    String? currentPageUrl,
    String? previousPageUrl,
    String? cookieHeader,
  }) {
    final origin = _safeOrigin(currentPageUrl) ?? _safeOrigin(targetUrl) ?? '';

    return {
      'Accept': '*/*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      'Referer': previousPageUrl ?? currentPageUrl ?? targetUrl,
      'Origin': origin,
      if (cookieHeader != null && cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
    };
  }

  static String? _safeOrigin(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri.origin;
  }

  static const String blobAndXhrHookScript = """
    window.flutter_inappwebview.callHandler('LogBridge', 'BlobParser script loaded');

    const _r_text = window.Response.prototype.text;
    window.Response.prototype.text = function () {
      return new Promise((resolve, reject) => {
        _r_text.call(this).then((text) => {
          resolve(text);
          const trimmed = text.trim();
          if (trimmed.startsWith('#EXTM3U') || trimmed.startsWith('<MPD') || trimmed.includes('"m3u8"') || trimmed.includes('"mpd"')) {
            window.flutter_inappwebview.callHandler('LogBridge', 'Media source found: ' + this.url);
            window.flutter_inappwebview.callHandler('VideoBridgeDebug', this.url);
          }
        }).catch(reject);
      });
    };

    const _open = window.XMLHttpRequest.prototype.open;
    window.XMLHttpRequest.prototype.open = function (...args) {
      this.addEventListener('load', () => {
        try {
          const content = this.responseText || '';
          const trimmed = content.trim();
          if (trimmed.startsWith('#EXTM3U') || trimmed.startsWith('<MPD') || trimmed.includes('"m3u8"') || trimmed.includes('"mpd"')) {
            window.flutter_inappwebview.callHandler('LogBridge', 'Media source found: ' + args[1]);
            window.flutter_inappwebview.callHandler('VideoBridgeDebug', args[1]);
          }
        } catch (_) {}
      });
      return _open.apply(this, args);
    };
  """;

  static const String runtimeDeobfuscationHookScript = """
    (function() {
      const mediaRegex = /(https?:\\/\\/[^"'\\s]+\\.(m3u8|mpd)(\\?[^"'\\s]*)?)/ig;

      function sampleText(text, from) {
        if (!text || typeof text !== 'string') return;
        const match = mediaRegex.exec(text);
        mediaRegex.lastIndex = 0;
        if (match && match[1]) {
          window.flutter_inappwebview.callHandler('LogBridge', '[runtime-hook:' + from + '] ' + match[1]);
          window.flutter_inappwebview.callHandler('VideoBridgeDebug', match[1]);
        }
      }

      const _atob = window.atob;
      window.atob = function(value) {
        const result = _atob.apply(this, arguments);
        sampleText(value, 'atob:before');
        sampleText(result, 'atob:after');
        return result;
      };

      const _decodeURIComponent = window.decodeURIComponent;
      window.decodeURIComponent = function(value) {
        const result = _decodeURIComponent.apply(this, arguments);
        sampleText(value, 'decodeURIComponent:before');
        sampleText(result, 'decodeURIComponent:after');
        return result;
      };

      const _eval = window.eval;
      window.eval = function(code) {
        sampleText(code, 'eval:before');
        const result = _eval.apply(this, arguments);
        try {
          sampleText(String(result || ''), 'eval:after');
        } catch (_) {}
        return result;
      };
    })();
  """;
}
