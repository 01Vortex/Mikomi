import 'dart:async';
import 'dart:io';

import 'package:mikomi/features/video/parse/parsing_android.dart';
import 'package:mikomi/features/video/parse/parsing_ios.dart';
import 'package:mikomi/features/video/services/video_stream_service.dart';

abstract class Parsing<T> {
  T? webviewController;
  int count = 0;
  int offset = 0;
  bool isIframeLoaded = false;
  bool isVideoSourceLoaded = false;
  VideoStreamResolveOptions resolveOptions = const VideoStreamResolveOptions();

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

  Future<void> loadUrl(
    String url,
    bool useAlternativeParser, {
    int offset = 0,
    VideoStreamResolveOptions options = const VideoStreamResolveOptions(),
  });

  Future<void> unloadPage();
  void dispose();
}

class ParsingFactory {
  static void setDocumentStartScriptSupported(bool supported) {}

  static Parsing getController() {
    if (Platform.isAndroid) {
      return ParsingAndroid();
    }
    return ParsingIos();
  }
}
