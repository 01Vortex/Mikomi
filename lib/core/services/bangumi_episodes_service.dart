import 'package:dio/dio.dart';
import 'package:mikomi/core/models/episode.dart';

class BangumiEpisodesService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.bgm.tv',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<Episode>> getEpisodesBySubjectId(int subjectId) async {
    try {
      final response = await _dio.get(
        '/v0/episodes',
        queryParameters: {
          'subject_id': subjectId,
          'type': 0, // 0=本篇
          'limit': 100,
          'offset': 0,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['data'] != null) {
          final List episodesJson = data['data'];
          return episodesJson.map((json) {
            return Episode(
              number: json['ep'] ?? 0,
              title: json['name_cn']?.isNotEmpty == true
                  ? json['name_cn']
                  : json['name'],
              url: null, // Bangumi API不提供视频URL
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      print('获取集数失败: $e');
      return [];
    }
  }
}
