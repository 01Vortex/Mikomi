import 'package:mikomi/features/video/origin/web/anti_anti_crawler/strategy.dart';

/// 浏览器指纹伪装——组合了 WebDriver 隐藏、指纹伪造、权限 API 拦截。
class BrowserStealth implements AntiCrawlerStrategy {
  const BrowserStealth();

  static const String _script = r'''
(function(){
  try {
    // WebDriver 检测隐藏
    Object.defineProperty(navigator, 'webdriver', { get: () => undefined });
    if (!window.chrome) { window.chrome = { runtime: {} }; }
    var origQuery = window.navigator.permissions.query;
    window.navigator.permissions.query = function(params) {
      return params.name === 'notifications'
        ? Promise.resolve({ state: Notification.permission })
        : origQuery(params);
    };
    ['__webdriver_evaluate','__selenium_evaluate','__webdriver_script_func',
     '__webdriver_script_fn','__fxdriver_evaluate','__driver_unwrapped',
     '__webdriver_unwrapped','__driver_evaluate','__selenium_unwrapped',
     '__fxdriver_unwrapped','_selenium','callSelenium','_Selenium_IDE_Recorder',
     '__selenium_ids','__webdriverFunc','_phantom','__phantomas',
     'domAutomation','domAutomationController'
    ].forEach(function(k) {
      try { Object.defineProperty(window, k, { get: function(){} }); } catch(_) {}
    });
    // 指纹伪造
    Object.defineProperty(navigator, 'language', { get: function(){ return 'zh-CN'; } });
    Object.defineProperty(navigator, 'languages', { get: function(){ return ['zh-CN','zh','en-US']; } });
    Object.defineProperty(navigator, 'plugins', { get: function(){ return [1,2,3,4,5]; } });
    Object.defineProperty(screen, 'availWidth', { get: function(){ return 1920; } });
    Object.defineProperty(screen, 'availHeight', { get: function(){ return 1080; } });
    // XMLHttpRequest.open 监控
    var _open = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function() { return _open.apply(this, arguments); };
  } catch(_) {}
})();
''';

  @override
  Future<void> onBeforeLoad(AntiCrawlerContext context) async {
    await context.controller?.evaluateJavascript(source: _script);
  }

  @override
  Future<void> onAfterLoad(AntiCrawlerContext context) async {
    await context.controller?.evaluateJavascript(source: _script);
  }

  @override
  void dispose() {}
}
