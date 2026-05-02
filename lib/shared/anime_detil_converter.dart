import 'package:flutter/material.dart';
import 'package:mikomi/config/app_routes.dart';
import 'package:mikomi/core/data/datasources/bangumi_source.dart';
import 'package:mikomi/core/models/anime.dart';
import 'package:mikomi/features/home/models/home_anime_model.dart';

class AnimeDetilConverter {
  AnimeDetilConverter._();

  static final BangumiSource _bangumiSource = BangumiSource();
  static final Map<String, Anime?> _cache = {};

  static Future<void> openBangumiDetail(
    BuildContext context,
    HomeAnimeModel source,
  ) async {
    final fallback = toAnime(source);
    final converted = await convertToBangumiAnime(source) ?? fallback;

    if (!context.mounted) return;
    Navigator.pushNamed(context, AppRoutes.animeDetail, arguments: converted);
  }

  static Anime toAnime(HomeAnimeModel source) {
    return Anime(
      id: source.id,
      name: source.name,
      nameCn: source.nameCn,
      summary: source.summary,
      airDate: source.airDate,
      images: source.images,
      ratingScore: source.ratingScore,
      ratingCount: source.ratingCount,
      rank: source.rank,
      tags: source.tags
          .map((tag) => BangumiTag(name: tag.name, count: tag.count))
          .toList(),
      info: source.info,
    );
  }

  static Future<Anime?> convertToBangumiAnime(HomeAnimeModel source) async {
    final titles = _candidateTitles(source);
    if (titles.isEmpty) return null;

    final cacheKey = titles
        .map(_normalizeTitle)
        .where((e) => e.isNotEmpty)
        .join('|');
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    for (final title in titles) {
      final anime = await _searchBangumiAnime(title, source);
      if (anime != null) {
        _cache[cacheKey] = anime;
        return anime;
      }
    }

    _cache[cacheKey] = null;
    return null;
  }

  static Future<Anime?> _searchBangumiAnime(
    String title,
    HomeAnimeModel source,
  ) async {
    try {
      final results = await _bangumiSource.searchSubjects(
        keyword: title,
        limit: 12,
      );
      if (results.isEmpty) return null;

      Anime? bestAnime;
      var bestScore = 0.0;

      for (final item in results) {
        if (item is! Map) continue;
        final anime = Anime.fromJson(Map<String, dynamic>.from(item));
        final score = _matchScore(anime, source);
        if (score > bestScore) {
          bestScore = score;
          bestAnime = anime;
        }
      }

      return bestScore >= 0.72 ? bestAnime : null;
    } catch (_) {
      return null;
    }
  }

  static List<String> _candidateTitles(HomeAnimeModel source) {
    final rawTitles = <String>[
      source.nameCn,
      source.name,
      source.displayName,
    ];

    final titles = <String>[];
    for (final raw in rawTitles) {
      final normalized = _normalizeWhitespace(raw);
      if (normalized.isEmpty) continue;
      titles.add(normalized);
    }

    for (final raw in rawTitles) {
      final base = _removeSeason(_normalizeWhitespace(raw));
      if (base.isNotEmpty) titles.add(base);
    }

    return titles.toSet().toList();
  }

  static double _matchScore(Anime anime, HomeAnimeModel source) {
    final sourceTitles = [source.nameCn, source.name, source.displayName]
        .map(_normalizeWhitespace)
        .where((e) => e.isNotEmpty)
        .toList();
    final animeTitles = [anime.nameCn, anime.name, anime.displayName]
        .map(_normalizeWhitespace)
        .where((e) => e.isNotEmpty)
        .toList();

    final sourceSeason = _extractSeason(sourceTitles.join(' '));
    final animeSeason = _extractSeason(animeTitles.join(' '));
    final sourceNormalized = sourceTitles.map(_normalizeTitle).toSet();
    final animeNormalized = animeTitles.map(_normalizeTitle).toSet();
    final sourceBase = sourceTitles.map(_normalizeBaseTitle).toSet();
    final animeBase = animeTitles.map(_normalizeBaseTitle).toSet();

    var score = 0.0;

    for (final sourceTitle in sourceNormalized) {
      for (final animeTitle in animeNormalized) {
        if (sourceTitle.isEmpty || animeTitle.isEmpty) continue;
        if (sourceTitle == animeTitle) {
          score = 1.0;
          break;
        }
        if (sourceTitle.contains(animeTitle) || animeTitle.contains(sourceTitle)) {
          score = score < 0.9 ? 0.9 : score;
          continue;
        }
        final similarity = _similarity(sourceTitle, animeTitle);
        if (similarity > score) score = similarity;
      }
    }

    final hasSameBase = sourceBase.any(
      (sourceTitle) => animeBase.any(
        (animeTitle) => sourceTitle.isNotEmpty && sourceTitle == animeTitle,
      ),
    );

    if (sourceSeason != null) {
      if (animeSeason == sourceSeason && hasSameBase) {
        score = score < 0.98 ? 0.98 : score;
      } else if (animeSeason == null && hasSameBase) {
        score = score > 0.58 ? 0.58 : score;
      } else if (animeSeason != null && animeSeason != sourceSeason) {
        score -= 0.45;
      }
    } else if (animeSeason != null && hasSameBase) {
      score = score > 0.68 ? 0.68 : score;
    }

    final sourceYear = _extractYear(source.airDate);
    final candidateYear = _extractYear(anime.airDate);
    if (sourceYear != null && candidateYear != null) {
      score += sourceYear == candidateYear ? 0.08 : -0.12;
    }

    return score.clamp(0, 1);
  }

  static String _normalizeWhitespace(String title) {
    return title.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _removeSeason(String title) {
    return title
        .replaceAll(RegExp(r'第\s*[一二三四五六七八九十0-9]+\s*季'), '')
        .replaceAll(RegExp(r'Season\s*\d+', caseSensitive: false), '')
        .replaceAll(RegExp(r'\bS\d+\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _normalizeTitle(String text) {
    return _normalizeWhitespace(text)
        .toLowerCase()
        .replaceAll('第二季', '第2季')
        .replaceAll('第三季', '第3季')
        .replaceAll('第四季', '第4季')
        .replaceAll('第五季', '第5季')
        .replaceAll('第六季', '第6季')
        .replaceAll('第七季', '第7季')
        .replaceAll('第八季', '第8季')
        .replaceAll('第九季', '第9季')
        .replaceAll('第十季', '第10季')
        .replaceAll(RegExp(r'season\s*(\d+)', caseSensitive: false), r'第$1季')
        .replaceAll(RegExp(r'\bs(\d+)\b', caseSensitive: false), r'第$1季')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[·•・:：\-—_!！?？,，.。/\\()（）\[\]【】《》「」『』]'), '');
  }

  static String _normalizeBaseTitle(String text) {
    return _normalizeTitle(_removeSeason(text));
  }

  static int? _extractSeason(String text) {
    final normalized = _normalizeWhitespace(text);
    final digit = RegExp(r'第\s*(\d+)\s*季').firstMatch(normalized);
    if (digit != null) return int.tryParse(digit.group(1)!);

    final chinese = RegExp(r'第\s*([一二三四五六七八九十]+)\s*季').firstMatch(normalized);
    if (chinese != null) return _chineseNumberToInt(chinese.group(1)!);

    final season = RegExp(
      r'Season\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (season != null) return int.tryParse(season.group(1)!);

    final shortSeason = RegExp(
      r'\bS(\d+)\b',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (shortSeason != null) return int.tryParse(shortSeason.group(1)!);

    return null;
  }

  static int? _chineseNumberToInt(String value) {
    const map = {
      '一': 1,
      '二': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
      '十': 10,
    };
    if (map.containsKey(value)) return map[value];
    if (value.startsWith('十')) {
      return 10 + (map[value.substring(1)] ?? 0);
    }
    if (value.endsWith('十')) {
      return (map[value.substring(0, value.length - 1)] ?? 0) * 10;
    }
    if (value.contains('十')) {
      final parts = value.split('十');
      final tens = map[parts.first] ?? 1;
      final ones = parts.length > 1 ? map[parts.last] ?? 0 : 0;
      return tens * 10 + ones;
    }
    return null;
  }

  static int? _extractYear(String text) {
    final match = RegExp(r'(19|20)\d{2}').firstMatch(text);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  static double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    final distance = _levenshtein(a, b);
    final maxLength = a.length > b.length ? a.length : b.length;
    return 1 - distance / maxLength;
  }

  static int _levenshtein(String a, String b) {
    final rows = a.length + 1;
    final cols = b.length + 1;
    final matrix = List.generate(rows, (_) => List<int>.filled(cols, 0));

    for (var i = 0; i < rows; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j < cols; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final deletion = matrix[i - 1][j] + 1;
        final insertion = matrix[i][j - 1] + 1;
        final substitution = matrix[i - 1][j - 1] + cost;
        matrix[i][j] = [deletion, insertion, substitution]
            .reduce((value, element) => value < element ? value : element);
      }
    }

    return matrix[a.length][b.length];
  }
}
