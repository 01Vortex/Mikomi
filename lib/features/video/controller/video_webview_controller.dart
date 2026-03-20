import 'dart:async';

/// WebView 视频解析控制器抽象类
abstract class VideoWebviewController<T> {
  // Webview controller
  T? webviewController;

  // 重试次数
  int count = 0;
  // 播放位置偏移
  int offset = 0;
  bool isIframeLoaded = false;
  bool isVideoSourceLoaded = false;

  /// Webview 初始化方法
  Future<void> init();

  final StreamController<bool> initEventController =
      StreamController<bool>.broadcast();

  // 初始化完成事件流
  Stream<bool> get onInitialized => initEventController.stream;

  final StreamController<String> logEventController =
      StreamController<String>.broadcast();

  // 日志事件流
  Stream<String> get onLog => logEventController.stream;

  final StreamController<bool> videoLoadingEventController =
      StreamController<bool>.broadcast();

  // 视频加载状态事件流
  Stream<bool> get onVideoLoading => videoLoadingEventController.stream;

  // 视频URL解析完成事件流
  // 第一个参数是视频URL，第二个参数是播放位置偏移
  final StreamController<(String, int)> videoParserEventController =
      StreamController<(String, int)>.broadcast();

  Stream<(String, int)> get onVideoURLParser =>
      videoParserEventController.stream;

  /// 加载URL
  Future<void> loadUrl(String url, bool useLegacyParser, {int offset = 0});

  /// 卸载页面
  Future<void> unloadPage();

  /// 释放资源
  void dispose();
}
