import 'package:mikomi/core/models/bangumi_item.dart';
import 'package:mikomi/core/network/dio_client.dart';
import 'package:mikomi/features/home/data/rank_record.dart';

class AniListRankData {
  final DioClient _dioClient = DioClient();

  Future<List<RankRecord>> getPlayRank({
    bool japaneseOnly = false,
    int limit = 30,
  }) {
    return _fetchRank(
      limit: limit,
      sort: 'POPULARITY_DESC',
      metricField: 'popularity',
      japaneseOnly: japaneseOnly,
    );
  }

  Future<List<RankRecord>> getCollectionRank({
    int limit = 30,
  }) {
    return _fetchRank(
      limit: limit,
      sort: 'FAVOURITES_DESC',
      metricField: 'favourites',
      japaneseOnly: false,
    );
  }

  Future<List<RankRecord>> _fetchRank({
    required int limit,
    required String sort,
    required String metricField,
    required bool japaneseOnly,
  }) async {
    try {
      final query = japaneseOnly ? _jpQuery : _baseQuery;

      final variables = {
        'page': 1,
        'perPage': limit,
        'sort': [sort],
      };

      if (japaneseOnly) {
        variables['country'] = 'JP';
      }

      final response = await _dioClient.post(
        'https://graphql.anilist.co',
        data: {
          'query': query,
          'variables': variables,
        },
      );

      final List<dynamic> mediaList =
          response.data['data']?['Page']?['media'] ?? [];

      final result = <RankRecord>[];
      for (final media in mediaList) {
        if (media is! Map<String, dynamic>) {
          continue;
        }

        final id = (media['id'] as num?)?.toInt() ?? 0;
        if (id <= 0) {
          continue;
        }

        final titleMap = media['title'] as Map<String, dynamic>? ?? {};
        final coverMap = media['coverImage'] as Map<String, dynamic>? ?? {};
        final score100 = (media['averageScore'] as num?)?.toDouble() ?? 0;
        final genres = (media['genres'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

        final item = BangumiItem(
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
          tags: genres.map((g) => BangumiTag(name: g, count: 0)).toList(),
          info: '',
        );

        final metric = (media[metricField] as num?)?.toInt() ?? 0;
        result.add(RankRecord(item: item, metric: metric));
      }

      return result;
    } catch (_) {
      return [];
    }
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

  static const String _baseQuery = '''
query (
  \$page: Int,
  \$perPage: Int,
  \$sort: [MediaSort]
) {
  Page(page: \$page, perPage: \$perPage) {
    media(type: ANIME, sort: \$sort) {
      id
      title {
        romaji
        english
        native
      }
      coverImage {
        large
        medium
      }
      averageScore
      popularity
      favourites
      startDate {
        year
        month
        day
      }
      genres
    }
  }
}
''';

  static const String _jpQuery = '''
query (
  \$page: Int,
  \$perPage: Int,
  \$sort: [MediaSort],
  \$country: CountryCode
) {
  Page(page: \$page, perPage: \$perPage) {
    media(type: ANIME, sort: \$sort, countryOfOrigin: \$country) {
      id
      title {
        romaji
        english
        native
      }
      coverImage {
        large
        medium
      }
      averageScore
      popularity
      favourites
      startDate {
        year
        month
        day
      }
      genres
    }
  }
}
''';
}
