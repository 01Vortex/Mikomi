class GeneralVideoParser {
  static bool needsSecondaryParsing(String url) {
    final lower = url.toLowerCase();
    if (looksLikeDirectMedia(lower)) return false;
    return lower.contains('.html') ||
        lower.contains('.php') ||
        lower.contains('player') ||
        lower.contains('play') ||
        lower.contains('index.php') ||
        lower.contains('/embed') ||
        lower.contains('/iframe');
  }

  static bool isM3U8Url(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') ||
        lower.contains('type=m3u8') ||
        lower.contains('format=m3u8') ||
        lower.contains('playlist.m3u8');
  }

  static bool isRangeVideoRequest(String url, Map<String, String>? headers) {
    if (headers == null) return false;
    final hasRange = headers.keys.any((k) => k.toLowerCase() == 'range');
    if (!hasRange) return false;

    final lower = url.toLowerCase();
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

  static bool looksLikeDirectMedia(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') ||
        lower.contains('.mp4') ||
        lower.contains('.flv') ||
        lower.contains('.ts') ||
        lower.contains('.m4s') ||
        lower.contains('.mpd');
  }

  static bool looksLikePlayableMedia(String url) {
    final lower = url.toLowerCase();
    if (lower.startsWith('blob:') || lower.startsWith('data:')) return false;

    return looksLikeDirectMedia(lower) ||
        lower.contains('token=') ||
        lower.contains('signature=') ||
        lower.contains('expires=') ||
        lower.contains('x-signature=');
  }

  static String normalizePossibleUrl(String raw, [String? baseUrl]) {
    var value = raw.trim();
    if (value.isEmpty) return value;

    if (value.startsWith('//')) {
      value = 'https:$value';
    }

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) return value;

    if (baseUrl != null) {
      final base = Uri.tryParse(baseUrl);
      if (base != null) {
        return base.resolve(value).toString();
      }
    }

    return value;
  }

  static String decodeVideoSource(String iframeUrl) {
    final decodedUrl = Uri.decodeFull(iframeUrl);
    final regExp = RegExp(
      r'(http[s]?://.*?\.(m3u8|mp4|mpd|m4s|flv|ts))',
      caseSensitive: false,
    );

    final uri = Uri.tryParse(decodedUrl);
    if (uri == null) return Uri.encodeFull(decodedUrl);

    var matchedUrl = decodedUrl;
    for (final entry in uri.queryParameters.entries) {
      if (regExp.hasMatch(entry.value)) {
        matchedUrl = entry.value;
        break;
      }
    }

    return Uri.encodeFull(matchedUrl);
  }

  static const String videoTagParserScript = """
    window.flutter_inappwebview.callHandler('LogBridge', 'VideoTagParser script loaded');

    function processVideoElement(video) {
      let src = video.currentSrc || video.getAttribute('src');
      if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.startsWith('data:') && !src.includes('googleads')) {
        window.flutter_inappwebview.callHandler('VideoBridgeDebug', src);
        _observer.disconnect();
        return true;
      }

      const sources = video.getElementsByTagName('source');
      for (let source of sources) {
        src = source.getAttribute('src');
        if (src && src.trim() !== '' && !src.startsWith('blob:') && !src.startsWith('data:') && !src.includes('googleads')) {
          window.flutter_inappwebview.callHandler('VideoBridgeDebug', src);
          _observer.disconnect();
          return true;
        }
      }
      return false;
    }

    const _observer = new MutationObserver((mutations) => {
      for (const mutation of mutations) {
        if (mutation.type === 'attributes' && mutation.target.nodeName === 'VIDEO') {
          if (processVideoElement(mutation.target)) return;
          continue;
        }
        for (const node of mutation.addedNodes) {
          if (node.nodeName === 'VIDEO') {
            if (processVideoElement(node)) return;
          }
          if (node.querySelectorAll) {
            for (const video of node.querySelectorAll('video')) {
              if (processVideoElement(video)) return;
            }
          }
        }
      }
    });

    function setupVideoProcessing() {
      for (const video of document.querySelectorAll('video')) {
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
}
