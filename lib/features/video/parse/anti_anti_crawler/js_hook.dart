import 'package:mikomi/features/video/parse/anti_anti_crawler/anti_anti_crawler.dart';

class JsHook implements AntiAntiCrawler {
  const JsHook();

  @override
  Future<void> onBeforeLoad(AntiAntiCrawlerContext context) async {
    await context.controller?.evaluateJavascript(source: '''
      (function(){
        try {
          const _open = XMLHttpRequest.prototype.open;
          XMLHttpRequest.prototype.open = function (...args) {
            return _open.apply(this, args);
          };
        } catch(_) {}
      })();
    ''');
  }

  @override
  Future<void> onAfterLoad(AntiAntiCrawlerContext context) async {}

  @override
  void dispose() {}
}
