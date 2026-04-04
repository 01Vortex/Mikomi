import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/repository/small_title_repository.dart';

class SmallTitleService {
  final SmallTitleRepository _repository;

  SmallTitleService({SmallTitleRepository? repository})
    : _repository = repository ?? SmallTitleRepository();

  Future<List<Episode>> applyEpisodeSmallTitles({
    required List<Episode> episodes,
    int? bangumiId,
    String? animeTitle,
    String? animeName,
  }) async {
    if (episodes.isEmpty) return episodes;

    final episodeNumbers = episodes
        .map((episode) => episode.number)
        .where((number) => number > 0)
        .toList();
    final smallTitles = await _repository.loadEpisodeSmallTitles(
      bangumiId: bangumiId,
      animeTitle: animeTitle,
      animeName: animeName,
      episodeNumbers: episodeNumbers,
    );

    return episodes.map((episode) {
      final candidateSmallTitle = smallTitles[episode.number]?.trim();
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

  bool _isGenericTitle(String? title) {
    if (title == null || title.trim().isEmpty) return true;
    final normalizedTitle = title.trim().toLowerCase();
    return RegExp(r'^(第?\d+[集话]|ep\s*\d+|\d+)$').hasMatch(normalizedTitle);
  }
}
