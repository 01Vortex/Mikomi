import 'package:flutter/foundation.dart';
import 'package:mikomi/core/data/datasources/anilist_episode_title_source.dart';
import 'package:mikomi/core/data/datasources/bangumi_episode_title_source.dart';

class SmallTitleRepository {
  final BangumiEpisodeTitleSource _primarySource;
  final AniListEpisodeTitleSource _secondarySource;

  SmallTitleRepository({
    BangumiEpisodeTitleSource? primarySource,
    AniListEpisodeTitleSource? secondarySource,
  }) : _primarySource = primarySource ?? BangumiEpisodeTitleSource(),
       _secondarySource = secondarySource ?? AniListEpisodeTitleSource();

  Future<Map<int, String>> loadEpisodeSmallTitles({
    int? bangumiId,
    String? animeTitle,
    String? animeName,
    required List<int> episodeNumbers,
  }) async {
    if (episodeNumbers.isEmpty) return {};

    final requested = episodeNumbers.toSet();
    final merged = <int, String>{};

    try {
      if (bangumiId != null && bangumiId > 0) {
        final primaryTitles = await _primarySource.fetchEpisodeTitles(bangumiId);
        for (final item in primaryTitles) {
          final number = item['number'] as int? ?? 0;
          final title = item['title']?.toString().trim() ?? '';
          if (number <= 0 || !requested.contains(number) || title.isEmpty) continue;
          merged[number] = title;
        }
      }
    } catch (e) {
      debugPrint('小标题主源加载失败: $e');
    }

    try {
      final keywords = <String>{
        if (animeTitle != null && animeTitle.trim().isNotEmpty) animeTitle.trim(),
        if (animeName != null && animeName.trim().isNotEmpty) animeName.trim(),
      };

      for (final keyword in keywords) {
        final secondaryTitles = await _secondarySource.fetchEpisodeTitlesBySearch(
          keyword,
        );
        for (final item in secondaryTitles) {
          final number = item['number'] as int? ?? 0;
          final title = item['title']?.toString().trim() ?? '';
          if (number <= 0 || !requested.contains(number) || title.isEmpty) continue;
          merged[number] ??= title;
        }

        if (merged.length == requested.length) break;
      }
    } catch (e) {
      debugPrint('小标题次源加载失败: $e');
    }

    return _dedupeByTitle(merged);
  }

  Map<int, String> _dedupeByTitle(Map<int, String> source) {
    final used = <String>{};
    final result = <int, String>{};

    final sorted = source.keys.toList()..sort();
    for (final number in sorted) {
      final title = source[number]?.trim() ?? '';
      if (title.isEmpty) continue;

      final normalized = title.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      if (used.contains(normalized)) continue;

      used.add(normalized);
      result[number] = title;
    }

    return result;
  }
}
