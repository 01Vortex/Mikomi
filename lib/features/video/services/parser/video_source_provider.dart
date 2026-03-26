import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mikomi/features/video/services/parser/video_webview_controller.dart';

// ──────────────────────────────────────────────
// 数据模型
// ──────────────────────────────────────────────

enum VideoSourceType { online, cached }

class VideoSource {
  final String url;
  final int offset;
  final VideoSourceType type;

  const VideoSource({
    required this.url,
    required this.offset,
    required this.type,
  });

  @override
  String toString() => 'VideoSource(url: $url, offset: $offset, type: $type)';
}

// ──────────────────────────────────────────────
// 异常类
// ──────────────────────────────────────────────

class VideoSourceNotFoundException implements Exception {
  final String message;
  const VideoSourceNotFoundException(
      [this.message = 'Video source not found']);

  @override
  String toString() => 'VideoSourceNotFoundException: $message';
}

class VideoSourceTimeoutException implements Exception {
  final Duration timeout;
  const VideoSourceTimeoutException(this.timeout);

  @override
  String toString() =>
      'VideoSourceTimeoutException: Timed out after ${timeout.inSeconds}s';
}

class VideoSourceCancelledException implements Exception {
  const VideoSourceCancelledException();

  @override
  String toString() =>
      'VideoSourceCancelledException: Resolution was cancelled';
}

class CaptchaRequiredException implements Exception {
  final String pluginName;
  final String pageUrl;
  final int captchaType;
  final String captchaImageXpath;
  final String captchaInputXpath;
  final String captchaButtonXpath;

  CaptchaRequiredException({
    required this.pluginName,
    required this.pageUrl,
    required this.captchaType,
    required this.captchaImageXpath,
    required this.captchaInputXpath,
    required this.captchaButtonXpath,
  });

  @override
  String toString() =>
      'CaptchaRequiredException(plugin=$pluginName, page=$pageUrl, type=$captchaType)';
}

// ──────────────────────────────────────────────
// 接口
// ──────────────────────────────────────────────

abstract class IVideoSourceProvider {
  Future<VideoSource> resolve(
    String episodeUrl, {
    required bool useLegacyParser,
    int offset = 0,
    Duration timeout = const Duration(seconds: 30),
  });

  void cancel();
  void dispose();
}

// ──────────────────────────────────────────────
// WebView 实现（照搬 Kazumi WebViewVideoSourceProvider）
// ──────────────────────────────────────────────

/// WebView 视频源提供者
///
/// WebView 实例在 Provider 生命周期内复用，切换集数时调用 unloadPage 释放页面资源，
/// 仅在 [dispose] 时才真正销毁 WebView。
class WebViewVideoSourceProvider implements IVideoSourceProvider {
  VideoWebviewController? _webview;
  StreamSubscription<String>? _logSubscription;

  /// 通过递增 ID 标识最新请求，取消旧请求
  int _resolveId = 0;

  @override
  Future<VideoSource> resolve(
    String episodeUrl, {
    required bool useLegacyParser,
    int offset = 0,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    _resolveId++;
    final currentResolveId = _resolveId;

    if (_webview == null) {
      _webview = VideoWebviewControllerFactory.getController();
      await _webview!.init();

      _logSubscription = _webview!.onLog.listen((log) {
        debugPrint('[WebView] $log');
      });
    }

    try {
      await _webview!.loadUrl(
        episodeUrl,
        useLegacyParser,
        offset: offset,
      );

      if (currentResolveId != _resolveId) {
        throw const VideoSourceCancelledException();
      }

      final event = await _webview!.onVideoURLParser.first.timeout(
        timeout,
        onTimeout: () {
          if (currentResolveId != _resolveId) {
            throw const VideoSourceCancelledException();
          }
          throw VideoSourceTimeoutException(timeout);
        },
      );

      if (currentResolveId != _resolveId) {
        throw const VideoSourceCancelledException();
      }

      debugPrint('========== 最终解析结果 ==========');
      debugPrint('视频流URL: ${event.$1}');
      debugPrint('==================================');

      return VideoSource(
        url: event.$1,
        offset: event.$2,
        type: VideoSourceType.online,
      );
    } catch (e) {
      if (e is VideoSourceCancelledException) rethrow;
      if (currentResolveId != _resolveId) {
        throw const VideoSourceCancelledException();
      }
      rethrow;
    } finally {
      if (currentResolveId == _resolveId) {
        await _webview?.unloadPage();
      }
    }
  }

  @override
  void cancel() {
    _resolveId++;
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
