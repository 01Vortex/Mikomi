import 'package:mikomi/features/video/parse/anti_anti_crawler/anti_anti_crawler.dart';

class WebdriverHider implements AntiAntiCrawler {
  const WebdriverHider();

  @override
  Future<void> onBeforeLoad(AntiAntiCrawlerContext context) async {
    await context.controller?.evaluateJavascript(source: '''
      (function(){
        try {
          Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        } catch(_) {}
      })();
    ''');
  }

  @override
  Future<void> onAfterLoad(AntiAntiCrawlerContext context) async {}

  @override
  void dispose() {}
}
