import 'package:mikomi/features/video/parse/anti_anti_crawler/anti_anti_crawler.dart';

class RequestInterceptor implements AntiAntiCrawler {
  const RequestInterceptor();

  bool shouldAllow(String lowerUrl) {
    if (lowerUrl.contains('googleads')) return false;
    if (lowerUrl.contains('googlesyndication')) return false;
    if (lowerUrl.contains('doubleclick')) return false;
    return true;
  }

  @override
  Future<void> onBeforeLoad(AntiAntiCrawlerContext context) async {}

  @override
  Future<void> onAfterLoad(AntiAntiCrawlerContext context) async {}

  @override
  void dispose() {}
}
