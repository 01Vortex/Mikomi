import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mikomi/features/video/parse/parsing.dart';
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

class VideoStreamResolveOptions {
  final int captchaType;
  final String captchaImageXpath;
  final String captchaInputXpath;
  final String captchaButtonXpath;

  const VideoStreamResolveOptions({
    this.captchaType = 0,
    this.captchaImageXpath = '',
    this.captchaInputXpath = '',
    this.captchaButtonXpath = '',
  });

  bool get hasCaptchaConfig =>
      captchaType > 0 ||
      captchaImageXpath.isNotEmpty ||
      captchaInputXpath.isNotEmpty ||
      captchaButtonXpath.isNotEmpty;
}

abstract class VideoStreamService {
  Future<ParsedVideoStream> resolveFromPage(
    String episodeUrl, {
    required bool useAlternativeParser,
    int offset = 0,
    Duration timeout = const Duration(seconds: 45),
    VideoStreamResolveOptions options = const VideoStreamResolveOptions(),
  });

  void cancel();
  void dispose();
}

class WebViewVideoStreamService implements VideoStreamService {
  Parsing? _parser;
  StreamSubscription<String>? _logSubscription;
  int _requestId = 0;

  @override
  Future<ParsedVideoStream> resolveFromPage(
    String episodeUrl, {
    required bool useAlternativeParser,
    int offset = 0,
    Duration timeout = const Duration(seconds: 45),
    VideoStreamResolveOptions options = const VideoStreamResolveOptions(),
  }) async {
    _requestId++;
    final currentRequestId = _requestId;

    if (_parser == null) {
      _parser = ParsingFactory.getController();
      await _parser!.init();

      _logSubscription = _parser!.onLog.listen((log) {
        debugPrint('[WebView] $log');
      });
    }

    try {
      await _parser!.loadUrl(
        episodeUrl,
        useAlternativeParser,
        offset: offset,
        options: options,
      );

      if (currentRequestId != _requestId) {
        throw const VideoStreamCancelledException();
      }

      final event = await _parser!.onVideoURLParser.first.timeout(
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
      throw VideoException(
        VideoExceptionCode.parseFailed,
        detail: e.toString(),
      );
    } finally {
      if (currentRequestId == _requestId) {
        await _parser?.unloadPage();
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
    _parser?.dispose();
    _parser = null;
  }
}
