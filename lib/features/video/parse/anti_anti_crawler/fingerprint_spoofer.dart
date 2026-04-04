import 'package:mikomi/features/video/parse/anti_anti_crawler/anti_anti_crawler.dart';

class FingerprintSpoofer implements AntiAntiCrawler {
  const FingerprintSpoofer();

  @override
  Future<void> onBeforeLoad(AntiAntiCrawlerContext context) async {
    await context.controller?.evaluateJavascript(source: '''
      (function(){
        try {
          Object.defineProperty(navigator, 'language', { get: () => 'zh-CN' });
          Object.defineProperty(navigator, 'languages', { get: () => ['zh-CN', 'zh', 'en-US'] });
          Object.defineProperty(navigator, 'plugins', { get: () => [1,2,3,4,5] });
          Object.defineProperty(screen, 'availWidth', { get: () => 1920 });
          Object.defineProperty(screen, 'availHeight', { get: () => 1080 });
        } catch(_) {}
      })();
    ''');
  }

  @override
  Future<void> onAfterLoad(AntiAntiCrawlerContext context) async {}

  @override
  void dispose() {}
}

