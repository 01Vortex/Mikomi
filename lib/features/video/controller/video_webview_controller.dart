import 'dart:async';
import 'dart:io';
import 'package:mikomi/features/video/services/video_webview_android_impl.dart';
import 'package:mikomi/features/video/services/video_webview_impl.dart';

abstract class VideoWebviewController<T> {
  T? webviewController;
  int count = 0;
  int offset = 0;
  bool isIframeLoaded = false;
  bool isVideoSourceLoaded = false;

  Future<void> init();

  final StreamController<bool> initEventController =
      StreamController<bool>.broadcast();
  Stream<bool> get onInitialized => initEventController.stream;

  final StreamController<String> logEventController =
      StreamController<String>.broadcast();
  Stream<String> get onLog => logEventController.stream;

  final StreamController<bool> videoLoadingEventController =
      StreamController<bool>.broadcast();
  Stream<bool> get onVideoLoading => videoLoadingEventController.stream;

  final StreamController<(String, int)> videoParserEventController =
      StreamController<(String, int)>.broadcast();
  Stream<(String, int)> get onVideoURLParser =>
      videoParserEventController.stream;

  Future<void> loadUrl(String url, bool useLegacyParser, {int offset = 0});
  Future<void> unloadPage();
  void dispose();
}

class VideoWebviewControllerFactory {
  static void setDocumentStartScriptSupported(bool supported) {}

  static VideoWebviewController getController() {
    if (Platform.isAndroid) {
      return VideoWebviewAndroidImpl();
    }
    return VideoWebviewImpl();
  }
}
