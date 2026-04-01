import 'package:mikomi/core/data/datasources/anilist_source.dart';
import 'package:mikomi/core/data/datasources/bangumi_source.dart';
import 'package:mikomi/features/home/models/home_anime_model.dart';
import 'package:mikomi/features/home/service/display_service.dart';
import 'package:mikomi/features/home/service/slider_image_service.dart';

class HomeRepository {
  final BangumiSource _bangumiSource = BangumiSource();
  final AniListSource _aniListSource = AniListSource();

  Future<List<HomeAnimeModel>> getRecommendedList({
    int limit = 12,
    int offset = 0,
  }) async {
    final fetchLimit = offset + limit + 24;

    final primaryItems = await _fetchBangumiHomeItems(fetchLimit);
    final source = primaryItems.isNotEmpty
        ? primaryItems
        : await _fetchAniListHomeItems(fetchLimit);

    return DisplayService.buildRecommendPage(
      source: source,
      limit: limit,
      offset: offset,
    );
  }

  Future<List<HomeAnimeModel>> getBannerList({int count = 5}) async {
    final primaryItems = await _fetchBangumiHomeItems(60);
    final source = primaryItems.isNotEmpty
        ? primaryItems
        : await _fetchAniListHomeItems(60);

    return SliderImageService.selectTopBanners(source, count: count);
  }

  Future<List<List<HomeAnimeModel>>> getCalendar() async {
    try {
      final jsonData = await _bangumiSource.fetchCalendar();
      final calendar = <List<HomeAnimeModel>>[];

      for (var i = 1; i <= 7; i++) {
        final dayList = <HomeAnimeModel>[];
        final jsonList = jsonData['$i'] as List? ?? [];
        for (final jsonItem in jsonList) {
          try {
            final item = jsonItem as Map<String, dynamic>;
            final subjectData = item['subject'] ?? item;
            dayList.add(
              HomeAnimeModel.fromJson(Map<String, dynamic>.from(subjectData)),
            );
          } catch (_) {}
        }
        calendar.add(dayList);
      }

      return calendar;
    } catch (_) {
      return List.generate(7, (_) => <HomeAnimeModel>[]);
    }
  }

  Future<List<RankRecord>> getPlayRank({
    bool japaneseOnly = false,
    int limit = 30,
  }) async {
    final mediaList = await _aniListSource.fetchMedia(
      page: 1,
      perPage: limit,
      sort: 'POPULARITY_DESC',
      country: japaneseOnly ? 'JP' : null,
    );

    return _mapAniListRank(mediaList, metricField: 'popularity');
  }

  Future<List<RankRecord>> getCollectionRank({int limit = 30}) async {
    final mediaList = await _aniListSource.fetchMedia(
      page: 1,
      perPage: limit,
      sort: 'FAVOURITES_DESC',
    );

    return _mapAniListRank(mediaList, metricField: 'favourites');
  }

  Future<List<RankRecord>> getJapaneseRank({int limit = 30}) async {
    final mediaList = await _aniListSource.fetchMedia(
      page: 1,
      perPage: limit,
      sort: 'SCORE_DESC',
      country: 'JP',
    );

    return _mapAniListRank(mediaList, metricField: 'averageScore');
  }

  Future<List<RankRecord>> getChineseRank({int limit = 30}) async {
    final mediaList = await _aniListSource.fetchMedia(
      page: 1,
      perPage: limit,
      sort: 'POPULARITY_DESC',
      country: 'CN',
    );

    return _mapAniListRank(mediaList, metricField: 'popularity');
  }

  Future<List<HomeAnimeModel>> _fetchBangumiHomeItems(int limit) async {
    try {
      final data = await _bangumiSource.fetchTrends(limit: limit, offset: 0);
      return data
          .whereType<Map>()
          .map((item) => HomeAnimeModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<HomeAnimeModel>> _fetchAniListHomeItems(int limit) async {
    try {
      final mediaList = await _aniListSource.fetchMedia(
        page: 1,
        perPage: limit,
        sort: 'POPULARITY_DESC',
      );

      return mediaList
          .whereType<Map>()
          .map((item) => _mapAniListItem(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<RankRecord> _mapAniListRank(
    List<dynamic> mediaList, {
    required String metricField,
  }) {
    final result = <RankRecord>[];

    for (final media in mediaList) {
      if (media is! Map<String, dynamic>) {
        continue;
      }

      final item = _mapAniListItem(media);
      if (item.id <= 0) {
        continue;
      }

      final metric = (media[metricField] as num?)?.toInt() ?? 0;
      result.add(RankRecord(item: item, metric: metric));
    }

    return result;
  }

  HomeAnimeModel _mapAniListItem(Map<String, dynamic> media) {
    final id = (media['id'] as num?)?.toInt() ?? 0;
    final titleMap = media['title'] as Map<String, dynamic>? ?? {};
    final coverMap = media['coverImage'] as Map<String, dynamic>? ?? {};
    final score100 = (media['averageScore'] as num?)?.toDouble() ?? 0;
    final genres = (media['genres'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return HomeAnimeModel(
      id: id,
      name:
          titleMap['romaji']?.toString() ??
          titleMap['english']?.toString() ??
          titleMap['native']?.toString() ??
          '',
      nameCn:
          titleMap['native']?.toString() ??
          titleMap['english']?.toString() ??
          titleMap['romaji']?.toString() ??
          '',
      summary: genres.join(' / '),
      airDate: _buildDate(media['startDate']),
      images: {
        'large': coverMap['large']?.toString() ?? '',
        'common': coverMap['medium']?.toString() ?? '',
        'medium': coverMap['medium']?.toString() ?? '',
        'small': coverMap['medium']?.toString() ?? '',
        'grid': coverMap['medium']?.toString() ?? '',
      },
      ratingScore: (score100 / 10).clamp(0, 10),
      ratingCount: (media['popularity'] as num?)?.toInt() ?? 0,
      rank: 0,
      tags: genres.map((g) => HomeAnimeTag(name: g, count: 0)).toList(),
      info: '',
    );
  }

  String _buildDate(dynamic startDateRaw) {
    if (startDateRaw is! Map<String, dynamic>) {
      return '';
    }

    final year = (startDateRaw['year'] as num?)?.toInt();
    final month = (startDateRaw['month'] as num?)?.toInt();
    final day = (startDateRaw['day'] as num?)?.toInt();

    if (year == null || year <= 0) {
      return '';
    }

    final safeMonth = (month == null || month <= 0) ? 1 : month;
    final safeDay = (day == null || day <= 0) ? 1 : day;
    final mm = safeMonth.toString().padLeft(2, '0');
    final dd = safeDay.toString().padLeft(2, '0');
    return '$year-$mm-$dd';
  }
}

class RankRecord {
  final HomeAnimeModel item;
  final int metric;

  const RankRecord({required this.item, required this.metric});
}
