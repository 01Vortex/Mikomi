import 'package:mikomi/features/home/models/home_anime_model.dart';
import 'package:mikomi/features/home/data/anilist_rank_data.dart';
import 'package:mikomi/features/home/data/rank_record.dart';
import 'package:mikomi/features/home/data/tencent_rank_data.dart';

enum RankCategory { play, collection, chinese, japanese }

class RankService {
  final AniListRankData _aniListRankData = AniListRankData();
  final TencentRankData _tencentRankData = TencentRankData();

  final Map<int, int> _metricById = {};

  Future<List<HomeAnimeModel>> getRankList(
    RankCategory category, {
    int limit = 30,
  }) async {
    List<RankRecord> records;

    switch (category) {
      case RankCategory.play:
        records = await _aniListRankData.getPlayRank(limit: limit);
        break;
      case RankCategory.collection:
        records = await _aniListRankData.getCollectionRank(limit: limit);
        break;
      case RankCategory.chinese:
        records = await _tencentRankData.getChineseAnimeRank(limit: limit);
        break;
      case RankCategory.japanese:
        records = await _aniListRankData.getPlayRank(
          japaneseOnly: true,
          limit: limit,
        );
        break;
    }

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
    final text = '${item.name}|${item.nameCn}|${item.info}|${item.tags.map((e) => e.name).join('|')}';
    return text.contains('国创') ||
        text.contains('国漫') ||
        text.contains('国产') ||
        text.contains('中国');
  }
}
