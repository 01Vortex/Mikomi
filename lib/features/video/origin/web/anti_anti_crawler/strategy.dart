import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mikomi/features/video/models/stream_resolve_options.dart';

class AntiCrawlerContext {
  final InAppWebViewController? controller;
  final String requestUrl;
  final bool useAlternativeParser;
  final int offset;
  final VideoStreamResolveOptions options;

  const AntiCrawlerContext({
    required this.controller,
    required this.requestUrl,
    required this.useAlternativeParser,
    required this.offset,
    this.options = const VideoStreamResolveOptions(),
  });
}

abstract class AntiCrawlerStrategy {
  Future<void> onBeforeLoad(AntiCrawlerContext context);
  Future<void> onAfterLoad(AntiCrawlerContext context);
  void dispose();
}
