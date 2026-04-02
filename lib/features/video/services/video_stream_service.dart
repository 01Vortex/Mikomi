import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mikomi/features/video/parse/video_webview.dart';
import 'package:mikomi/features/video/services/video_exception.dart';

enum ParsedVideoStreamType { online, cached }

class ParsedVideoStream {
  final String url;
  final int offset;
  final ParsedVideoStreamType type;

  const ParsedVideoStream({
    required this.url,
    required this.offset,
    required this.type,
  });

  @override
  String toString() =>
      'ParsedVideoStream(url: $url, offset: $offset, type: $type)';
}

abstract class VideoStreamService {
  Future<ParsedVideoStream> resolveFromPage(
    String episodeUrl, {
    required bool useLegacyParser,
    int offset = 0,
    Duration timeout = const Duration(seconds: 45),
  });

  void cancel();
  void dispose();
}

class WebViewVideoStreamService implements VideoStreamService {
  VideoWebview? _webview;
  StreamSubscription<String>? _logSubscription;
  int _requestId = 0;

  @override
  Future<ParsedVideoStream> resolveFromPage(
    String episodeUrl, {
    required bool useLegacyParser,
    int offset = 0,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    _requestId++;
    final currentRequestId = _requestId;

    if (_webview == null) {
      _webview = VideoWebviewFactory.getController();
      await _webview!.init();

      _logSubscription = _webview!.onLog.listen((log) {
        debugPrint('[WebView] $log');
      });
    }

    try {
      await _webview!.loadUrl(episodeUrl, useLegacyParser, offset: offset);

      if (currentRequestId != _requestId) {
        throw const VideoStreamCancelledException();
      }

      final event = await _webview!.onVideoURLParser.first.timeout(
        timeout,
        onTimeout: () {
          if (currentRequestId != _requestId) {
            throw const VideoStreamCancelledException();
          }
          throw VideoStreamTimeoutException(timeout);
        },
      );

      if (currentRequestId != _requestId) {
        throw const VideoStreamCancelledException();
      }

      if (event.$1.trim().isEmpty) {
        throw const VideoStreamNotFoundException('解析后的视频流地址为空');
      }

      return ParsedVideoStream(
        url: event.$1,
        offset: event.$2,
        type: ParsedVideoStreamType.online,
      );
    } catch (e) {
      if (e is VideoStreamCancelledException ||
          e is VideoStreamTimeoutException ||
          e is VideoStreamNotFoundException) {
        rethrow;
      }
      if (currentRequestId != _requestId) {
        throw const VideoStreamCancelledException();
      }
      throw VideoException(VideoExceptionCode.parseFailed, detail: e.toString());
    } finally {
      if (currentRequestId == _requestId) {
        await _webview?.unloadPage();
      }
    }
  }

  @override
  void cancel() {
    _requestId++;
  }

  @override
  void dispose() {
    cancel();
    _logSubscription?.cancel();
    _logSubscription = null;
    _webview?.dispose();
    _webview = null;
  }
}
