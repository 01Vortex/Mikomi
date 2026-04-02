import 'package:flutter/foundation.dart';
import 'package:mikomi/core/data/datasources/bangumi_episodes_source.dart';
import 'package:mikomi/features/video/models/episode_model.dart';

class EpisodesRepository {
  final BangumiEpisodesSource _source;

  EpisodesRepository({BangumiEpisodesSource? source})
    : _source = source ?? BangumiEpisodesSource();

  Future<List<Episode>> getEpisodesBySubjectId(int subjectId) async {
    try {
      final data = await _source.fetchEpisodesBySubjectId(subjectId);

      return data.whereType<Map>().map((json) {
        final item = Map<String, dynamic>.from(json);
        return Episode(
          number: item['ep'] ?? 0,
          title: item['name_cn']?.isNotEmpty == true
              ? item['name_cn']
              : item['name'],
          url: null,
        );
      }).toList();
    } catch (e) {
      debugPrint('获取集数失败: $e');
      return [];
    }
  }
}
