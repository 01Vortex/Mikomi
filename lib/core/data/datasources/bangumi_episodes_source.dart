import 'package:dio/dio.dart';

class BangumiEpisodesSource {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.bgm.tv',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  Future<List<dynamic>> fetchEpisodesBySubjectId(int subjectId) async {
    final response = await _dio.get(
      '/v0/episodes',
      queryParameters: {
        'subject_id': subjectId,
        'type': 0,
        'limit': 100,
        'offset': 0,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return (data['data'] as List?)?.cast<dynamic>() ?? [];
      }
    }

    return [];
  }
}
