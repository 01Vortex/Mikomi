import 'dart:math';

import 'package:html/parser.dart' as html_parser;
import 'package:mikomi/core/data/datasources/anilist_source.dart';
import 'package:mikomi/core/data/datasources/tencent_source.dart';
import 'package:mikomi/features/home/models/home_anime_model.dart';

class ScheduleService {
  final AniListSource _aniListSource;
  final TencentSource _tencentSource;

  static DateTime? _lastLoadedAt;
  static List<List<HomeAnimeModel>>? _cachedSchedule;
  static Future<List<List<HomeAnimeModel>>>? _inFlight;

  static const Duration _cacheDuration = Duration(minutes: 10);

  ScheduleService({AniListSource? aniListSource, TencentSource? tencentSource})
    : _aniListSource = aniListSource ?? AniListSource(),
      _tencentSource = tencentSource ?? TencentSource();

  Future<List<List<HomeAnimeModel>>> getWeekSchedule({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _hasValidCache()) {
      return _cachedSchedule!;
    }

    final running = _inFlight;
    if (running != null) {
      return running;
    }

    final task = _loadWeekSchedule();
    _inFlight = task;

    try {
      final result = await task;
      _cachedSchedule = result;
      _lastLoadedAt = DateTime.now();
      return result;
    } finally {
      _inFlight = null;
    }
  }

  bool _hasValidCache() {
    final cached = _cachedSchedule;
    final loadedAt = _lastLoadedAt;
    if (cached == null || loadedAt == null) {
      return false;
    }

    return DateTime.now().difference(loadedAt) < _cacheDuration;
  }

  Future<List<List<HomeAnimeModel>>> _loadWeekSchedule() async {
    final results = await Future.wait([
      _getJapaneseAiringItems(),
      _getChineseAiringItems(),
    ]);

    final all = <HomeAnimeModel>[
      ...results[0],
      ...results[1],
    ];

    final unique = <int, HomeAnimeModel>{};
    for (final item in all) {
      unique[item.id] = item;
    }

    final schedule = List.generate(7, (_) => <HomeAnimeModel>[]);
    for (final anime in unique.values) {
      final parsed = _parseWeekIndexAndTime(anime.airDate);
      if (parsed == null) {
        continue;
      }
      schedule[parsed.weekIndex].add(anime);
    }

    for (final dayList in schedule) {
      dayList.sort((a, b) {
        final aTime = _extractTime(a.airDate);
        final bTime = _extractTime(b.airDate);
        return aTime.compareTo(bTime);
      });
    }

    return schedule;
  }

  Future<List<HomeAnimeModel>> _getJapaneseAiringItems() async {
    final result = <HomeAnimeModel>[];

    for (var page = 1; page <= 4; page++) {
      final mediaList = await _aniListSource.fetchAiringSchedule(
        page: page,
        perPage: 50,
      );

      if (mediaList.isEmpty) {
        break;
      }

      for (final media in mediaList) {
        if (media is! Map<String, dynamic>) {
          continue;
        }

        final country = media['countryOfOrigin']?.toString() ?? '';
        if (country != 'JP') {
          continue;
        }

        final nextAiring = media['nextAiringEpisode'];
        if (nextAiring is! Map<String, dynamic>) {
          continue;
        }

        final airingAt = (nextAiring['airingAt'] as num?)?.toInt();
        if (airingAt == null || airingAt <= 0) {
          continue;
        }

        result.add(_mapJapaneseItem(media, nextAiring));
      }

      if (mediaList.length < 50) {
        break;
      }
    }

    return result;
  }

  Future<List<HomeAnimeModel>> _getChineseAiringItems() async {
    final html = await _tencentSource.fetchChineseRankHtml(limit: 120);
    final document = html_parser.parse(html);
    final cards = document.querySelectorAll('.list_item');

    final result = <HomeAnimeModel>[];

    for (var i = 0; i < cards.length; i++) {
      final card = cards[i];
      final titleAnchor = card.querySelector('.figure_title');
      final coverAnchor = card.querySelector('a.figure');
      final image = card.querySelector('img.figure_pic');
      final desc = card.querySelector('.figure_desc');
      final caption = card.querySelector('.figure_caption');

      final title =
          titleAnchor?.attributes['title']?.trim() ??
          titleAnchor?.text.trim() ??
          coverAnchor?.attributes['title']?.trim() ??
          '';
      final rawCover = image?.attributes['src']?.trim() ?? '';
      final cover = _normalizeUrl(rawCover);
      final href =
          coverAnchor?.attributes['href']?.trim() ??
          titleAnchor?.attributes['href']?.trim() ??
          '';
      final summary =
          desc?.attributes['title']?.trim() ?? desc?.text.trim() ?? '';
      final captionText =
          caption?.attributes['title']?.trim() ?? caption?.text.trim() ?? '';

      if (title.isEmpty || cover.isEmpty) {
        continue;
      }

      final parsedSlot =
          _parseTencentSlot(summary) ?? _parseTencentSlot(title);
      final slot =
          parsedSlot ?? (weekIndex: i % 7, hour: 20, minute: 0);

      final airingDateTime = _buildLocalDateForWeekIndex(
        slot.weekIndex,
        slot.hour,
        slot.minute,
      );
      final hh = airingDateTime.hour.toString().padLeft(2, '0');
      final mm = airingDateTime.minute.toString().padLeft(2, '0');
      final weekText = _weekdayText((slot.weekIndex + 1));
      final hasExactSlot = parsedSlot != null;
      final episodeText = _extractTencentEpisode(
        title: title,
        summary: summary,
        caption: captionText,
      );

      result.add(
        HomeAnimeModel(
          id: _stableId(href.isEmpty ? '$title-$i' : href),
          name: title,
          nameCn: title,
          summary: summary,
          airDate:
              '${airingDateTime.year.toString().padLeft(4, '0')}-${airingDateTime.month.toString().padLeft(2, '0')}-${airingDateTime.day.toString().padLeft(2, '0')} $hh:$mm',
          images: {
            'large': cover,
            'common': cover,
            'medium': cover,
            'small': cover,
            'grid': cover,
          },
          ratingScore: 0,
          ratingCount: 0,
          rank: 0,
          tags: const [HomeAnimeTag(name: '国漫', count: 0)],
          info: hasExactSlot
              ? '国漫 · $weekText $hh:$mm${episodeText.isEmpty ? '' : ' · $episodeText'}'
              : '国漫 · $weekText 时间待定${episodeText.isEmpty ? '' : ' · $episodeText'}',
        ),
      );
    }

    return result;
  }

  HomeAnimeModel _mapJapaneseItem(
    Map<String, dynamic> media,
    Map<String, dynamic> nextAiring,
  ) {
    final id = (media['id'] as num?)?.toInt() ?? 0;
    final titleMap = media['title'] as Map<String, dynamic>? ?? {};
    final coverMap = media['coverImage'] as Map<String, dynamic>? ?? {};
    final score100 = (media['averageScore'] as num?)?.toDouble() ?? 0;
    final popularity = (media['popularity'] as num?)?.toInt() ?? 0;
    final genres = (media['genres'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final airingAt = (nextAiring['airingAt'] as num?)?.toInt() ?? 0;
    final episode = (nextAiring['episode'] as num?)?.toInt();
    final airingDateTime = DateTime.fromMillisecondsSinceEpoch(
      airingAt * 1000,
      isUtc: true,
    ).toLocal();

    final weekText = _weekdayText(airingDateTime.weekday);
    final hh = airingDateTime.hour.toString().padLeft(2, '0');
    final mm = airingDateTime.minute.toString().padLeft(2, '0');
    final episodeText = episode == null ? '' : '第$episode话';
    final info = '日漫 · $weekText $hh:$mm $episodeText'.trim();

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
      airDate:
          '${airingDateTime.year.toString().padLeft(4, '0')}-${airingDateTime.month.toString().padLeft(2, '0')}-${airingDateTime.day.toString().padLeft(2, '0')} $hh:$mm',
      images: {
        'large': coverMap['large']?.toString() ?? '',
        'common': coverMap['medium']?.toString() ?? '',
        'medium': coverMap['medium']?.toString() ?? '',
        'small': coverMap['medium']?.toString() ?? '',
        'grid': coverMap['medium']?.toString() ?? '',
      },
      ratingScore: (score100 / 10).clamp(0, 10),
      ratingCount: popularity,
      rank: 0,
      tags: genres.map((g) => HomeAnimeTag(name: g, count: 0)).toList(),
      info: info,
    );
  }

  ({int weekIndex, int hour, int minute})? _parseTencentSlot(String text) {
    final weekMatch = RegExp(r'每周([一二三四五六日天])').firstMatch(text);
    final timeMatch = RegExp(r'(\d{1,2})[:：](\d{2})').firstMatch(text);
    if (weekMatch == null || timeMatch == null) {
      return null;
    }

    final weekChar = weekMatch.group(1);
    final hour = int.tryParse(timeMatch.group(1) ?? '');
    final minute = int.tryParse(timeMatch.group(2) ?? '');
    if (weekChar == null || hour == null || minute == null) {
      return null;
    }

    final weekIndex = switch (weekChar) {
      '一' => 0,
      '二' => 1,
      '三' => 2,
      '四' => 3,
      '五' => 4,
      '六' => 5,
      '日' || '天' => 6,
      _ => -1,
    };

    if (weekIndex < 0) {
      return null;
    }

    return (weekIndex: weekIndex, hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  DateTime _buildLocalDateForWeekIndex(int weekIndex, int hour, int minute) {
    final now = DateTime.now();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));

    var date = monday.add(Duration(days: weekIndex));
    date = DateTime(date.year, date.month, date.day, hour, minute);

    if (date.isBefore(now.subtract(const Duration(hours: 1)))) {
      date = date.add(const Duration(days: 7));
    }

    return date;
  }

  ({int weekIndex, int minutesOfDay})? _parseWeekIndexAndTime(String airDate) {
    if (airDate.isEmpty) {
      return null;
    }

    DateTime dateTime;
    try {
      dateTime = DateTime.parse(airDate);
    } catch (_) {
      return null;
    }

    final weekIndex = (dateTime.weekday + 6) % 7;
    final minutesOfDay = dateTime.hour * 60 + dateTime.minute;
    return (weekIndex: weekIndex, minutesOfDay: minutesOfDay);
  }

  int _extractTime(String airDate) {
    final parsed = _parseWeekIndexAndTime(airDate);
    return parsed?.minutesOfDay ?? 0;
  }

  String _weekdayText(int weekday) {
    const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return labels[(weekday + 6) % 7];
  }

  String _normalizeUrl(String url) {
    if (url.isEmpty) {
      return '';
    }
    if (url.startsWith('//')) {
      return 'https:$url';
    }
    return url;
  }

  String _extractTencentEpisode({
    required String title,
    required String summary,
    required String caption,
  }) {
    final text = '$title $summary $caption';

    final patterns = <RegExp>[
      RegExp(r'第\s*(\d+)\s*[话話]'),
      RegExp(r'第\s*(\d+)\s*集'),
      RegExp(r'更新至\s*(\d+)\s*集'),
      RegExp(r'更新到\s*(\d+)\s*集'),
      RegExp(r'EP\s*(\d+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      final ep = match?.group(1);
      if (ep != null && ep.isNotEmpty) {
        return '第$ep话';
      }
    }

    return '';
  }

  int _stableId(String text) {
    var hash = 0;
    for (final codeUnit in text.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return max(hash, 1);
  }
}
