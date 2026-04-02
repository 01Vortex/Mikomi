import 'package:mikomi/features/video/parse/anti_anti_crawler/anti_anti_crawler.dart';

class CaptchaHandler implements AntiAntiCrawler {
  const CaptchaHandler();

  bool detect(String html) {
    final lower = html.toLowerCase();
    return lower.contains('captcha') ||
        lower.contains('验证码') ||
        lower.contains('verify') ||
        lower.contains('turnstile');
  }

  @override
  Future<void> onBeforeLoad(AntiAntiCrawlerContext context) async {}

  @override
  Future<void> onAfterLoad(AntiAntiCrawlerContext context) async {}

  @override
  void dispose() {}
}
