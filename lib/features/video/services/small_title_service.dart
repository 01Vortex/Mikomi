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

    final numberList = episodes.map((e) => e.number).where((n) => n > 0).toList();
    final smallTitles = await _repository.loadEpisodeSmallTitles(
      bangumiId: bangumiId,
      animeTitle: animeTitle,
      animeName: animeName,
      episodeNumbers: numberList,
    );

    return episodes.map((episode) {
      final candidateTitle = smallTitles[episode.number]?.trim();
      if (candidateTitle == null || candidateTitle.isEmpty) return episode;

      if (_isGenericTitle(episode.title)) {
        return Episode(
          number: episode.number,
          title: candidateTitle,
          url: episode.url,
        );
      }

      return Episode(
        number: episode.number,
        title: episode.title?.trim().isNotEmpty == true
            ? episode.title
            : candidateTitle,
        url: episode.url,
      );
    }).toList();
  }

  bool _isGenericTitle(String? title) {
    if (title == null || title.trim().isEmpty) return true;
    final t = title.trim().toLowerCase();
    return RegExp(r'^(第?\d+[集话]|ep\s*\d+|\d+)$').hasMatch(t);
  }
}
