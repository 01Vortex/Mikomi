import 'package:mikomi/core/data/datasources/dandanplay.dart';

class DanmakuRepository {
  final DanDanPlaySource _danDanPlaySource;

  DanmakuRepository({DanDanPlaySource? danDanPlaySource})
    : _danDanPlaySource = danDanPlaySource ?? DanDanPlaySource();

  Future<int?> resolveBangumiIdByTitle(String title) {
    return _danDanPlaySource.resolveBangumiIdByTitle(title);
  }

  Future<int?> resolveEpisodeIdByBangumiId(int bangumiId, int episode) {
    return _danDanPlaySource.resolveEpisodeIdByBangumiId(bangumiId, episode);
  }

  Future<int?> resolveEpisodeId({
    required int? bgmBangumiId,
    required String? animeTitle,
    required int episode,
  }) {
    return _danDanPlaySource.resolveEpisodeId(
      bgmBangumiId: bgmBangumiId,
      animeTitle: animeTitle,
      episode: episode,
    );
  }

  Future<List<dynamic>> fetchCommentsByEpisodeId(int episodeId) {
    return _danDanPlaySource.fetchCommentsByEpisodeId(episodeId);
  }
}
