import 'package:mikomi/features/video/parse/anti_anti_crawler/anti_anti_crawler.dart';

class CaptchaHandler implements AntiAntiCrawler {
  const CaptchaHandler();

  bool detect(String html) {
    final lower = html.toLowerCase();
    return lower.contains('captcha') ||
        lower.contains('验证码') ||
        lower.contains('verify') ||
        lower.contains('人机验证') ||
        lower.contains('geetest') ||
        lower.contains('turnstile') ||
        lower.contains('smart-verify') ||
        lower.contains('verify-panel') ||
        lower.contains('cf-browser-verification') ||
        lower.contains('checking your browser') ||
        lower.contains('just a moment') ||
        lower.contains('ddos-guard') ||
        lower.contains('__ddg') ||
        lower.contains('robot or human');
  }

  @override
  Future<void> onBeforeLoad(AntiAntiCrawlerContext context) async {}

  @override
  Future<void> onAfterLoad(AntiAntiCrawlerContext context) async {}

  @override
  void dispose() {}
}

