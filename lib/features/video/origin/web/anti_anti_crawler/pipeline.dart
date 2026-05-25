import 'package:mikomi/features/video/origin/web/anti_anti_crawler/strategy.dart';

/// 反爬虫策略管道——组合多个 [AntiCrawlerStrategy] 按序执行。
class AntiCrawlerPipeline implements AntiCrawlerStrategy {
  final List<AntiCrawlerStrategy> _strategies;

  const AntiCrawlerPipeline(this._strategies);

  @override
  Future<void> onBeforeLoad(AntiCrawlerContext context) async {
    for (final strategy in _strategies) {
      await strategy.onBeforeLoad(context);
    }
  }

  @override
  Future<void> onAfterLoad(AntiCrawlerContext context) async {
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
