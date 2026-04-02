import 'package:mikomi/features/video/parse/anti_anti_crawler/anti_anti_crawler.dart';

class CompositeAntiAntiCrawler implements AntiAntiCrawler {
  final List<AntiAntiCrawler> _strategies;

  const CompositeAntiAntiCrawler(this._strategies);

  @override
  Future<void> onBeforeLoad(AntiAntiCrawlerContext context) async {
    for (final strategy in _strategies) {
      await strategy.onBeforeLoad(context);
    }
  }

  @override
  Future<void> onAfterLoad(AntiAntiCrawlerContext context) async {
    for (final strategy in _strategies) {
      await strategy.onAfterLoad(context);
    }
  }

  @override
  void dispose() {
    for (final strategy in _strategies) {
      strategy.dispose();
    }
  }
}
