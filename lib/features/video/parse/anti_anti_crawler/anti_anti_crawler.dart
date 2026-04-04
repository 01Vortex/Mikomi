import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mikomi/features/video/services/video_parsing_service.dart';

class AntiAntiCrawlerContext {
  final InAppWebViewController? controller;
  final String requestUrl;
  final bool useAlternativeParser;
  final int offset;
  final VideoStreamResolveOptions options;

  const AntiAntiCrawlerContext({
    required this.controller,
    required this.requestUrl,
    required this.useAlternativeParser,
    required this.offset,
    this.options = const VideoStreamResolveOptions(),
  });
}

abstract class AntiAntiCrawler {
  Future<void> onBeforeLoad(AntiAntiCrawlerContext context);
  Future<void> onAfterLoad(AntiAntiCrawlerContext context);
  void dispose();
}
