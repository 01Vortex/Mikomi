import 'package:mikomi/features/video/parse/anti_anti_crawler/anti_anti_crawler.dart';

class WebdriverHider implements AntiAntiCrawler {
  const WebdriverHider();

  static const String _script = '''
    (function(){
      try {
        Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
        if (!window.chrome) { window.chrome = { runtime: {} }; }
        const origQuery = window.navigator.permissions.query;
        window.navigator.permissions.query = (params) => (
          params.name === 'notifications'
            ? Promise.resolve({ state: Notification.permission })
            : origQuery(params)
        );
        [
          '__webdriver_evaluate','__selenium_evaluate','__webdriver_script_func',
          '__webdriver_script_fn','__fxdriver_evaluate','__driver_unwrapped',
          '__webdriver_unwrapped','__driver_evaluate','__selenium_unwrapped',
          '__fxdriver_unwrapped','_selenium','callSelenium','_Selenium_IDE_Recorder',
          '__selenium_ids','__webdriverFunc','_phantom','__phantomas',
          'domAutomation','domAutomationController'
        ].forEach((k) => {
          try { Object.defineProperty(window, k, { get: () => undefined }); } catch(_) {}
        });
      } catch(_) {}
    })();
  ''';

  @override
  Future<void> onBeforeLoad(AntiAntiCrawlerContext context) async {
    await context.controller?.evaluateJavascript(source: _script);
  }

  @override
  Future<void> onAfterLoad(AntiAntiCrawlerContext context) async {
    await context.controller?.evaluateJavascript(source: _script);
  }

  @override
  void dispose() {}
}
