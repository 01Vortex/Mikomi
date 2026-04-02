import 'package:mikomi/features/video/models/episode_model.dart';
import 'package:mikomi/features/video/repository/episodes_repository.dart';

class EpisodesService {
  final EpisodesRepository _episodesRepository = EpisodesRepository();

  Future<List<Episode>> getEpisodesBySubjectId(int subjectId) async {
    return _episodesRepository.getEpisodesBySubjectId(subjectId);
  }
}
