import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class AntiAntiCrawlerContext {
  final InAppWebViewController? controller;
  final String requestUrl;
  final bool useAlternativeParser;
  final int offset;

  const AntiAntiCrawlerContext({
    required this.controller,
    required this.requestUrl,
    required this.useAlternativeParser,
    required this.offset,
  });
}

abstract class AntiAntiCrawler {
  Future<void> onBeforeLoad(AntiAntiCrawlerContext context);
  Future<void> onAfterLoad(AntiAntiCrawlerContext context);
  void dispose();
}
