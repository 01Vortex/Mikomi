import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mikomi/features/video/data/services/video_webview_android_impl.dart';

/// WebView 视频地址解析器
/// 完整参考 Kazumi 实现
class WebViewVideoParser {
  VideoWebviewAndroidImpl? _webviewController;
  StreamSubscription<(String, int)>? _videoUrlSubscription;
  StreamSubscription<String>? _logSubscription;
  Completer<String>? _videoUrlCompleter;
  Timer? _timeoutTimer;
  bool _isDisposed = false;

  Future<String?> parseVideoUrl(
    String pageUrl, {
    bool useLegacyParser = true,
    Duration timeout = const Duration(seconds: 30),
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

      // 创建并初始化 WebView 控制器
      _webviewController = VideoWebviewAndroidImpl();
      await _webviewController!.init();

      // 订阅日志事件
      _logSubscription = _webviewController!.onLog.listen((log) {
        debugPrint('WebView日志: $log');
      });

      // 订阅视频URL解析事件
      _videoUrlSubscription = _webviewController!.onVideoURLParser.listen((
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
      await _webviewController!.loadUrl(pageUrl, useLegacyParser);

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

  Future<void> dispose() async {
    _isDisposed = true;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    await _logSubscription?.cancel();
    _logSubscription = null;

    await _videoUrlSubscription?.cancel();
    _videoUrlSubscription = null;

    _webviewController?.dispose();
    _webviewController = null;

    _videoUrlCompleter = null;
  }
}
