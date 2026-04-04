import 'package:flutter/foundation.dart';
import 'package:mikomi/core/data/datasources/anilist_episode_title_source.dart';
import 'package:mikomi/core/data/datasources/bangumi_episode_title_source.dart';
import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/repository/video_episode_repository.dart';
import 'package:mikomi/features/video/exception/video_exception.dart';

class VideoEpisodeService {
  final VideoEpisodeRepository _repository;
  final BangumiEpisodeTitleSource _bangumiSource;
  final AniListEpisodeTitleSource _aniListSource;

  VideoEpisodeService({
    VideoEpisodeRepository? repository,
    BangumiEpisodeTitleSource? bangumiSource,
    AniListEpisodeTitleSource? aniListSource,
  }) : _repository = repository ?? VideoEpisodeRepository(),
       _bangumiSource = bangumiSource ?? BangumiEpisodeTitleSource(),
       _aniListSource = aniListSource ?? AniListEpisodeTitleSource();

  Future<List<Episode>> loadEpisodes({
    required String sourceName,
    required String? animeTitle,
    required String? animeName,
    required int? bangumiId,
  }) async {
    if (animeTitle == null) return [];

    try {
      final episodes = await _repository.fetchEpisodes(
        sourceName: sourceName,
        animeTitle: animeTitle,
        animeName: animeName,
      );

      return _applyEpisodeSmallTitles(
        episodes: episodes,
        bangumiId: bangumiId,
        animeTitle: animeTitle,
        animeName: animeName,
      );
    } on VideoCaptchaRequiredException {
      rethrow;
    } catch (e) {
      debugPrint('加载视频源剧集失败: $e');
      return [];
    }
  }

  Future<List<Episode>> _applyEpisodeSmallTitles({
    required List<Episode> episodes,
    int? bangumiId,
    String? animeTitle,
    String? animeName,
  }) async {
    if (episodes.isEmpty) return episodes;

    final titleMap = <int, String>{};

    if (bangumiId != null && bangumiId > 0) {
      final bangumiTitles = await _safeLoadBangumiTitles(bangumiId);
      _mergeSmallTitles(titleMap, bangumiTitles);
    }

    final searchKeyword = (animeTitle?.trim().isNotEmpty == true)
        ? animeTitle!.trim()
        : animeName?.trim();
    if (searchKeyword != null && searchKeyword.isNotEmpty) {
      final aniListTitles = await _safeLoadAniListTitles(searchKeyword);
      _mergeSmallTitles(titleMap, aniListTitles);
    }

    return episodes.map((episode) {
      final candidateSmallTitle = titleMap[episode.number]?.trim();
      if (candidateSmallTitle == null || candidateSmallTitle.isEmpty) {
        return episode;
      }

      if (_isGenericTitle(episode.smallTitle)) {
        return Episode(
          number: episode.number,
          smallTitle: candidateSmallTitle,
          url: episode.url,
        );
      }

      return Episode(
        number: episode.number,
        smallTitle: episode.smallTitle?.trim().isNotEmpty == true
            ? episode.smallTitle
            : candidateSmallTitle,
        url: episode.url,
      );
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _safeLoadBangumiTitles(int bangumiId) async {
    try {
      return await _bangumiSource.fetchEpisodeTitles(bangumiId);
    } catch (e) {
      debugPrint('Bangumi 小标题加载失败: $e');
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _safeLoadAniListTitles(String keyword) async {
    try {
      return await _aniListSource.fetchEpisodeTitlesBySearch(keyword);
    } catch (e) {
      debugPrint('AniList 小标题加载失败: $e');
      return const [];
    }
  }

  void _mergeSmallTitles(
    Map<int, String> target,
    List<Map<String, dynamic>> items,
  ) {
    for (final item in items) {
      final number = _toEpisodeNumber(item['number']);
      final title = item['title']?.toString().trim() ?? '';
      if (number <= 0 || title.isEmpty) continue;
      target.putIfAbsent(number, () => title);
    }
  }

  int _toEpisodeNumber(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _isGenericTitle(String? title) {
    if (title == null || title.trim().isEmpty) return true;
    final normalizedTitle = title.trim().toLowerCase();
    return RegExp(r'^(第?\d+[集话]|ep\s*\d+|\d+)$').hasMatch(normalizedTitle);
  }
}
