import 'package:mikomi/features/home/data/repositories/home_repository.dart';
import 'package:mikomi/features/home/models/home_anime_model.dart';

enum RankCategory { play, collection, chinese, japanese }

class RankService {
  final HomeRepository _repository = HomeRepository();
  final Map<int, int> _metricById = {};

  Future<List<HomeAnimeModel>> getRankList(
    RankCategory category, {
    int limit = 30,
  }) async {
    final records = switch (category) {
      RankCategory.play => await _repository.getPlayRank(limit: limit),
      RankCategory.collection => await _repository.getCollectionRank(limit: limit),
      RankCategory.chinese => await _repository.getChineseRank(limit: limit),
      RankCategory.japanese =>
        await _repository.getPlayRank(japaneseOnly: true, limit: limit),
    };

    _metricById
      ..clear()
      ..addEntries(records.map((record) => MapEntry(record.item.id, record.metric)));

    return records.map((record) => record.item).toList();
  }

  int metricValue(HomeAnimeModel item, RankCategory category) {
    return _metricById[item.id] ?? 0;
  }

  String metricLabel(RankCategory category) {
    switch (category) {
      case RankCategory.play:
      case RankCategory.japanese:
        return '人气';
      case RankCategory.collection:
        return '收藏';
      case RankCategory.chinese:
        return '热度';
    }
  }

  bool isChineseAnime(HomeAnimeModel item) {
    final text =
        '${item.name}|${item.nameCn}|${item.info}|${item.tags.map((e) => e.name).join('|')}';
    return text.contains('国创') ||
        text.contains('国漫') ||
        text.contains('国产') ||
        text.contains('中国');
  }
}
